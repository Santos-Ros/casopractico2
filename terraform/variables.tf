variable "resource_group_name" {
  description = "Nombre del resource group para el caso práctico 2"
  type        = string
  default     = "rg-casopractico2"
}

variable "location" {
  description = "Región de Azure donde desplegar los recursos."
}

variable "subscription_id" {
  description = "ID de suscripción de Azure. Déjalo en null para usar la suscripción activa de `az login` (no hace falta terraform.tfvars)"
  type        = string
  default     = null
}

variable "vm_admin_username" {
  description = "Usuario administrador de la VM Linux"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Tamaño de la VM Linux."
  type        = string
  default     = "Standard_B2s_v2"
}

variable "aks_node_vm_size" {
  description = "Tamaño de VM para el node pool de AKS."
  type        = string
  default     = "Standard_B2s_v2"
}