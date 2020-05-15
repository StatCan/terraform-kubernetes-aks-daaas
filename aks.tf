# Azure Kubernetes Service
resource "random_password" "windows_password" {
  length           = 16
  special          = true
  override_special = "_%@$"
}

resource "azurerm_kubernetes_cluster" "new_aks" {
  name                = "${var.new_prefix}-aks"
  location            = "${azurerm_resource_group.rg_aks.location}"
  resource_group_name = "${azurerm_resource_group.rg_aks.name}"
  dns_prefix          = "${var.new_prefix}-aks"

  kubernetes_version = "${var.kube_version}"

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${file(var.public_ssh_key_path)}"
    }
  }

  windows_profile {
    admin_username = "azureuser"
    admin_password = random_password.windows_password.result
  }

  default_node_pool {
    name                = "nodepool1"
    node_count          = "${var.node_count}"
    vm_size             = "${var.new_node_size}"
    os_disk_size_gb     = "${var.node_disk_size}"
    max_pods            = "${var.node_pod_count}"
    vnet_subnet_id      = "${azurerm_subnet.new_subnet_aks.id}"
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 20
  }

  service_principal {
    client_id     = "${azuread_application.client.application_id}"
    client_secret = "${azuread_service_principal_password.client.value}"
  }

  addon_profile {
    azure_policy {
      enabled = false
    }

    oms_agent {
      enabled                    = false
      log_analytics_workspace_id = "${azurerm_log_analytics_workspace.workspace_aks.id}"
    }
  }

  network_profile {
    network_plugin     = "${var.network_plugin}"
    network_policy     = "${var.network_policy}"
    docker_bridge_cidr = "${var.new_docker_bridge_cidr}"
    dns_service_ip     = "${var.dns_service_ip}"
    service_cidr       = "${var.service_cidr}"
    load_balancer_sku  = "${var.load_balancer_sku}"
  }

  role_based_access_control {
    enabled = true

    azure_active_directory {
      client_app_id     = "${azuread_application.client.application_id}"
      server_app_id     = "${azuread_application.server.application_id}"
      server_app_secret = "${azuread_service_principal_password.server.value}"
    }
  }

  tags = {
    Environment = "${var.environment}"
    wid         = "100117"
  }

  lifecycle {
    ignore_changes = [
      # Since autoscaling is enabled, let's ignore changes to the node count.
      default_node_pool[0].node_count,
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "new_gpupool1" {
  kubernetes_cluster_id = "${azurerm_kubernetes_cluster.new_aks.id}"
  name                  = "gpupool1"
  node_count            = "${var.gpu_node_count}"
  vm_size               = "${var.gpu_node_size}"
  os_type               = "Linux"
  os_disk_size_gb       = "${var.node_disk_size}"
  max_pods              = "${var.node_pod_count}"
  vnet_subnet_id        = "${azurerm_subnet.new_subnet_aks.id}"
  node_taints           = ["dedicated=gpu:NoSchedule"]
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 5

  lifecycle {
    ignore_changes = [
      # Since autoscaling is enabled, let's ignore changes to the node count.
      node_count,
    ]
  }
}
