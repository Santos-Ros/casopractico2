# Red virtual (Virtual Network)
resource "azurerm_virtual_network" "main" {
  name                = "vnet-casopractico2"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = "casopractico2"
  }
}


# Subred
resource "azurerm_subnet" "main" {
  name                 = "subnet-casopractico2"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}


# IP pública dinámica
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "public-ip-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "casopractico2"
  }
}


# Network Security Group (NSG)
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "nsg-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "casopractico2"
  }
}

#Network interface (NIC)
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }

  tags = {
    environment = "casopractico2"
  }
}

# Asociación de la NIC con el NSG
resource "azurerm_network_interface_security_group_association" "vm_nic_nsg" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

#Creacion de claves ssh
resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Creación de la máquina virtual
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm-casopractico2"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = var.vm_size

  admin_username        = var.vm_admin_username

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm_ssh_key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-casopractico2"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "24.04.202404230"
  }


  computer_name  = "vmcasopractico2"
  disable_password_authentication = true

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip python3-six
  EOF
  )
  
  tags = {
    environment = "casopractico2"
  }
}