output "resource_group_name" {
  description = "Nombre del resource group creado en Azure"
  value       = azurerm_resource_group.main.name
}

output "acr_name" {
  description = "Nombre del Azure Container Registry (generado con sufijo único)"
  value       = azurerm_container_registry.acr.name
}

output "acr_login_server" {
  description = "Login server del ACR"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Usuario administrador del ACR"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  description = "Contraseña del ACR"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "vm_admin_username" {
  description = "Usuario administrador de la VM"
  value       = var.vm_admin_username
}

output "vm_public_ip_address" {
  description = "Dirección IP pública asignada automáticamente a la VM"
  value       = azurerm_public_ip.vm_public_ip.ip_address
}

output "vm_private_key_pem" {
  description = "Clave privada SSH para acceder a la VM"
  value       = tls_private_key.vm_ssh_key.private_key_pem
  sensitive   = true
}

output "vm_public_ip" {
  value       = azurerm_public_ip.vm_public_ip.ip_address
  description = "IP pública de la VM para acceder por SSH"
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "db_password" {
  description = "Contraseña generada para la base de datos PostgreSQL"
  value       = random_password.db_password.result
  sensitive   = true
}

output "web_auth_password" {
  description = "Contraseña generada para el acceso HTTP básico de la web en Podman"
  value       = random_password.web_auth_password.result
  sensitive   = true
}

output "kube_config" {
  description = "Kubeconfig del clúster AKS, listo para usar con kubectl/kubernetes.core"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}