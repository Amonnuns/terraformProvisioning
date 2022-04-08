# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  
  required_version = ">= 0.13"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "myTFResourceGroup"
  location = var.node_location

  tags = {
    environment = "Terraform Learning"
  }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
  name = "myVnet"
  address_space = ["192.168.1.0/24"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "Terraform Learning"
  }
}

resource "azurerm_subnet" "myterraformsubnet" {
  name = "mySubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
  address_prefixes = ["192.168.1.0/24"]
}

resource "azurerm_public_ip" "myterraformpublicip" {
  
  count = 2
  name = "myPublicIP-${format("%d", count.index)}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"

  tags = {
    environment = "Terraform Learning"
  }
}


resource "azurerm_network_interface" "myterraformnic" {
  count = 2
  name = "myNic-${format("%d", count.index)}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "myNicConfiguration"
    subnet_id = azurerm_subnet.myterraformsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.myterraformpublicip.*.id, count.index) 
  }

   tags = {
    environment = "Terraform Learning"
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  count = 2
  network_interface_id      = element(azurerm_network_interface.myterraformnic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { 
    value = tls_private_key.example_ssh.private_key_pem 
    sensitive = true
}

resource "azurerm_linux_virtual_machine" "myterraformvm" {
  count = 2
  name = "myTerraformVM-${format("%d", count.index)}"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  network_interface_ids = [element(azurerm_network_interface.myterraformnic.*.id, count.index)]
  size = "Standard_B1s"

  os_disk {
    name = "myOsDisk-${count.index}"
    caching = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version   = "latest"
  }

  computer_name  = "myvm"
  admin_username = "amonnuns"
  disable_password_authentication = true

  admin_ssh_key {
    username = "amonnuns"
    public_key = file(var.ssh_file_path)
  }

  tags = {
    environment = "Terraform Learning"
  }
}


