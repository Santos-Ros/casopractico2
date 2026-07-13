resource "time_static" "acr_suffix" {}

resource "azurerm_container_registry" "acr" {
  name                = "acrcasopractico2${formatdate("YYYYMMDDhhmmss", time_static.acr_suffix.rfc3339)}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = {
    environment = "casopractico2"
  }
}