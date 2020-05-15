# Virtual Networks
resource "azurerm_virtual_network" "new_vnet_aks" {
  name                = "${var.new_prefix}-vnet"
  location            = "${azurerm_resource_group.rg_network_development.location}"
  resource_group_name = "${azurerm_resource_group.rg_network_development.name}"
  address_space       = ["${var.new_vnet_cidr}"]
}

resource "azurerm_subnet" "new_subnet_aks" {
  name                 = "containers"
  resource_group_name  = "${azurerm_resource_group.rg_network_development.name}"
  address_prefix       = "${var.new_subnet_cidr}"
  virtual_network_name = "${azurerm_virtual_network.new_vnet_aks.name}"
}
