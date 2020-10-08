provider "azurerm" {
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "aks-resources" {
  name     = "demo-resources"
  location = "West Europe"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "demo-aks1"
  location            = azurerm_resource_group.aks-resources.location
  resource_group_name = azurerm_resource_group.aks-resources.name
  dns_prefix          = "demoaks1"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
  }
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.example.kube_config_raw
}