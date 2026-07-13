#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$REPO_ROOT/terraform"
ANSIBLE_DIR="$REPO_ROOT/ansible"

echo "==> 1/4 Desplegando infraestructura con Terraform"
cd "$TF_DIR"
terraform init -input=false
terraform apply -auto-approve

echo "==> 2/4 Extrayendo credenciales y datos generados por Terraform"
terraform output -raw vm_private_key_pem > "$ANSIBLE_DIR/clave_vm.pem"
chmod 600 "$ANSIBLE_DIR/clave_vm.pem"

terraform output -raw kube_config > "$ANSIBLE_DIR/kubeconfig"
chmod 600 "$ANSIBLE_DIR/kubeconfig"

VM_IP="$(terraform output -raw vm_public_ip)"
VM_ADMIN_USER="$(terraform output -raw vm_admin_username)"
ACR_NAME="$(terraform output -raw acr_name)"
ACR_LOGIN_SERVER="$(terraform output -raw acr_login_server)"
ACR_ADMIN_USER="$(terraform output -raw acr_admin_username)"
ACR_ADMIN_PASSWORD="$(terraform output -raw acr_admin_password)"
DB_PASSWORD="$(terraform output -raw db_password)"
WEB_AUTH_PASSWORD="$(terraform output -raw web_auth_password)"

for var_name in VM_IP VM_ADMIN_USER ACR_NAME ACR_LOGIN_SERVER ACR_ADMIN_USER ACR_ADMIN_PASSWORD DB_PASSWORD WEB_AUTH_PASSWORD; do
  if [[ -z "${!var_name}" ]]; then
    echo "❌ El output de Terraform '${var_name}' ha salido vacío. Aborto antes de generar secrets.yml."
    echo "   Comprueba manualmente con: terraform -chdir=terraform output"
    exit 1
  fi
done

echo "==> 3/4 Generando inventario y variables de Ansible para este despliegue"
sed \
  -e "s/__VM_PUBLIC_IP__/${VM_IP}/" \
  -e "s/__VM_ADMIN_USER__/${VM_ADMIN_USER}/" \
  -e "s/__ACR_NAME__/${ACR_NAME}/" \
  -e "s/__ACR_LOGIN_SERVER__/${ACR_LOGIN_SERVER}/" \
  "$ANSIBLE_DIR/hosts.template" > "$ANSIBLE_DIR/hosts"

mkdir -p "$ANSIBLE_DIR/group_vars"
cat > "$ANSIBLE_DIR/group_vars/secrets.yml" <<EOF
# Generado automáticamente por deploy.sh a partir de los outputs de Terraform.
# No se versiona (ver .gitignore) y se regenera en cada despliegue.
acr_username: "${ACR_ADMIN_USER}"
acr_password: "${ACR_ADMIN_PASSWORD}"
acr_login_server: "${ACR_LOGIN_SERVER}"

kubeconfig_path: "${ANSIBLE_DIR}/kubeconfig"

db_name: encuesta
db_user: encuesta_user
db_password: "${DB_PASSWORD}"

web_auth_user: admin
web_auth_password: "${WEB_AUTH_PASSWORD}"
EOF
chmod 600 "$ANSIBLE_DIR/group_vars/secrets.yml"

echo "==> 4/4 Ejecutando Ansible (ACR + VM/Podman + AKS)"
cd "$ANSIBLE_DIR"
ansible-playbook -i hosts playbook.yml

ENCUESTA_IP="$(cat "$ANSIBLE_DIR/.encuesta_external_ip" 2>/dev/null || echo "no disponible")"

echo "✅ Despliegue completado."
echo ""
echo "   Web en Podman  -> https://${VM_IP}"
echo "     Usuario: admin"
echo "     Contraseña: ${WEB_AUTH_PASSWORD}"
echo ""
echo "   Encuesta en AKS -> http://${ENCUESTA_IP}"