provider "null" {}

resource "null_resource" "download_helm_chart" {
  provisioner "local-exec" {
    command = "helm pull stable/sonarqube --version 4.0.1"
  }
}

resource "azurerm_resource_group" "sonarqube_rg" {
  name     = "sonarqube-rg"
  location = "West US"
}

provider "kubernetes" {
  config_context_cluster = "sonarqube-aks"
  config_path            = "C:\\Users\\AMADALI\\.kube\\config"
}

resource "azurerm_kubernetes_cluster" "aks" {
  resource_group_name = azurerm_resource_group.sonarqube_rg.name
  name                = "sonarqube-aks"
  location            = azurerm_resource_group.sonarqube_rg.location
  dns_prefix          = "sonarqube-aks"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_DS2_v2"
    enable_auto_scaling = false
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.2.0.0/16"  # Update to a non-overlapping CIDR
    dns_service_ip = "10.2.0.10"     # Update as needed
  }
}


provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}


resource "helm_release" "sonarqube_new" {
  name       = "sq-new-release"
  chart      = "stable/sonarqube"
  version    = "4.0.1"  # Specify the version of the chart
  namespace  = "default"

  set {
    name  = "service.type"
    value = "LoadBalancer"  # Expose SonarQube service as LoadBalancer
  }

  set {
    name  = "service.port"
    value = "9000"  # Expose SonarQube on port 9000
  }
}
