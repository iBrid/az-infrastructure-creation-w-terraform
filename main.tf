terraform {
  required_version = ">=1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=4.0.0"
    }
  }
  cloud {
    organization = "DatacentR"
    workspaces {
      name = "az-infrastructure-creation-w-tf"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

resource "azurerm_resource_group" "rg" {
  name     = "myTerraformRG"
  location = "West US 2"
}

resource "azurerm_storage_account" "storage" {
  name                     = "mytfstg02211"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = "West US 2"
  account_replication_type = "LRS"
  account_tier             = "Standard"

  tags = {
    environment = "test env"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "mytfvnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West US 2"
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "test env"
  }
}

resource "azurerm_subnet" "snet" {
  name                 = "mytfsubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "mytfnsg1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West US 2"

  tags = {
    environment = "test env"
  }
}

resource "azurerm_network_security_rule" "nsrule" {
  name                        = "AllowRDP"
  access                      = "Allow"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  protocol                    = "Tcp"
  direction                   = "Inbound"
  priority                    = 100
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_public_ip" "pip" {
  name                = "mytfpip1"
  location            = "West US 2"
  allocation_method   = "Static"
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = "test env"
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "mytfpnic"
  location            = "West US 2"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.snet.id
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "mytfpvm1"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = "West US 2"
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_F2"
  admin_username        = "azureuser"
  admin_password        = "@dmin12345678"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "test env"
  }
} 