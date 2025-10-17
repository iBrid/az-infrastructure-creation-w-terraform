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
  name = "mytfvnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location = "West US 2"
  address_space = [ "10.0.0.0/16" ]
  
  tags = {
    environment = "test env"
  }
}