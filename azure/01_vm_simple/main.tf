provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "my_project_rg" {
  name     = "MyProjectResourceGroup"
  location = "westeurope"

  tags = {
    environment = "Terraform Demo"
  }
}