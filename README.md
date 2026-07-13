# Caso Práctico 2 – Automatización de Despliegues en Entornos Cloud

Infraestructura y despliegue 100% automatizados en Azure con Terraform y Ansible. Se despliegan
dos aplicaciones: una web estática en una VM con Podman, y una app con almacenamiento
persistente en un clúster AKS.

## Estructura del proyecto

```
├── deploy.sh
├── destroy.sh
├── terraform
│   ├── main.tf
│   ├── acr.tf
│   ├── secrets.tf
│   ├── vm.tf
│   ├── aks.tf
│   ├── variables.tf
│   └── output.tf
│
└── ansible
    ├── playbook.yml
    ├── hosts.template
    ├── group_vars/          # secrets.yml se genera aquí en tiempo de despliegue (no versionado)
    ├── roles/
        ├── acr
        ├── vm
        └── aks
```

## Requisitos previos (nodo de control)

Todo lo que sigue se instala **una sola vez, a mano, antes de lanzar `deploy.sh`**. No se automatiza
con Ansible porque instalar paquetes de sistema requiere privilegios de `root`, y `deploy.sh` está
pensado para ejecutarse sin intervención manual (sin contraseñas de `sudo` de por medio).

Se necesita: **Azure CLI**, **Terraform**, **Ansible**, **Podman** (se usa también en el propio nodo
de control, no solo en la VM: aquí es donde se construyen y suben las imágenes al ACR), **kubectl**,
**pip3**, y varias **colecciones de Ansible**.

### macOS (con [Homebrew](https://brew.sh))

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install azure-cli ansible podman kubectl python3

# Podman en macOS necesita una VM Linux ligera para ejecutar contenedores
podman machine init
podman machine start
```

### Linux (Ubuntu/Debian)

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform (repositorio oficial de HashiCorp)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install -y terraform

# Ansible, Podman y pip3
sudo apt-get update && sudo apt-get install -y ansible podman python3-pip

# kubectl (si el paquete "kubectl" no está en tus repos, usa la alternativa de abajo)
sudo apt-get install -y kubectl
# Alternativa si el paquete anterior no existe en tu distro:
sudo az aks install-cli
```

> Probado en Debian 12/13 y Ubuntu 24.04. En Debian, el paquete `kubectl` no siempre está
> disponible en los repos por defecto — en ese caso usa `az aks install-cli` (requiere `sudo`
> porque instala el binario en `/usr/local/bin`).

### Colecciones de Ansible (mismo comando en macOS y Linux)

```bash
ansible-galaxy collection install containers.podman kubernetes.core community.crypto community.general
```

### Autenticación en Azure

```bash
az login
```

Esto abre el navegador para iniciar sesión con la cuenta de Azure (Academy/Students). Terraform
reutiliza automáticamente esta sesión, así que no hace falta crear ningún fichero de credenciales.

## Cómo ejecutar

No hace falta rellenar ningún fichero de credenciales a mano. Terraform genera un nombre de ACR
único (con sufijo de timestamp) y todas las contraseñas necesarias (ACR, base de datos, acceso web);
`deploy.sh` las recoge automáticamente de los outputs de Terraform y las inyecta en Ansible.

### Desplegar todo

```bash
git clone <url-del-repo>
cd casopractico2
chmod +x deploy.sh destroy.sh
./deploy.sh
```

Al terminar, `deploy.sh` imprime en la terminal las URLs de acceso a **ambas** aplicaciones y la
contraseña generada para la web en Podman — no hace falta compartir ningún secreto por ningún
canal externo:

```
✅ Despliegue completado.

   Web en Podman  -> https://<IP_VM>
     Usuario: admin
     Contraseña: <generada automáticamente>

   Encuesta en AKS -> http://<IP_LOADBALANCER>
```

El script es **idempotente**: si algo falla a mitad de ejecución (problemas de red, límites
transitorios de la cuenta de Azure, etc.), basta con volver a lanzar `./deploy.sh` sin tocar nada.
Terraform no recrea lo que ya existe y coincide con el código, y los módulos de Ansible usados
son igualmente repetibles.

### Destruir todo

```bash
./destroy.sh
```

Elimina toda la infraestructura de Azure (incluido el grupo de recursos que AKS crea
automáticamente para sus nodos, `MC_<resource-group>_<cluster>_<región>`) y limpia los artefactos
locales generados (`clave_vm.pem`, `kubeconfig`, `hosts`, `secrets.yml`).

## Tecnologías utilizadas

- Azure (ACR, VM Linux, AKS)
- Terraform
- Ansible (`containers.podman`, `kubernetes.core`, `community.crypto`, `community.general`)
- Podman
- Apache httpd + TLS autofirmado + autenticación básica
- Flask + PostgreSQL

## Aplicaciones desplegadas

- **VM con Podman — "Rincón Motero":** servidor Apache sirviendo una página estática con
  temática motera, accesible por HTTPS con certificado autofirmado y usuario/contraseña
  (HTTP básico). El contenedor se registra como servicio `systemd`, por lo que sobrevive a un
  reinicio de la VM.
- **AKS con persistencia — "¿Naked o Deportiva?":** app Flask de encuesta con los votos
  almacenados en PostgreSQL, expuesta a Internet mediante un `Service` de tipo `LoadBalancer`.

## Notas de arquitectura

- El clúster AKS se crea con `sku_tier = "Free"` y un único nodo, dentro del límite de vCPU de la
  cuenta de estudiante de Azure.
- La región de despliegue por defecto es `swedencentral` — la cuenta de estudiante restringe las
  regiones disponibles vía Azure Policy; se puede comprobar con:
```bash
  az policy assignment list --query "[?displayName=='Allowed resource deployment regions'].parameters" -o json
```
- La app Flask **no tiene PVC propio**: es intencionado. No guarda estado en el pod, todo se
  escribe directamente en PostgreSQL, que sí tiene su propio `PersistentVolumeClaim`. El volumen
  de Postgres es independiente del ciclo de vida del pod, así que sobrevive a que el pod se
  elimine y se recree.

### Cómo validar la persistencia (sin depender de un PVC en la app)

```bash
export KUBECONFIG=ansible/kubeconfig

# 1. Votar un par de veces en http://<IP_LOADBALANCER> y anotar el contador

# 2. Eliminar el pod de PostgreSQL a propósito
kubectl delete pod -n motoapp -l app=postgres

# 3. Comprobar que se recrea solo
kubectl get pods -n motoapp -w

# 4. Volver a la web: los votos siguen ahí, porque persisten en el volumen, no en el pod
```