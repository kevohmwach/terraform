resource "azurerm_virtual_network" "VNET_terraform" {
  name                = "terraform-vnet"
  address_space       = [var.addr_space]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "SUBNET_prod_subnet" {
  name                 = "production-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.prod_subnet_prefixes]
}
resource "azurerm_subnet" "db_subnet" {
  name                 = "db-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.db_subnet_prefixes]
#   service_endpoints    = ["Microsoft.Storage"]

  # Delegate this subnet specifically to MySQL Flexible Server
  delegation {
    name = "mysql_delegation"
    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "appservice_subnet" {
  name                 = "appservice-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNET_terraform.name
  address_prefixes     = [var.appservice_subnet_prefixes]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.KeyVault"]

  # Delegate this subnet specifically to MySQL Flexible Server
  delegation {
    name = "webapp_delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}
# Create a Private DNS Zone (So app can find DB by name)
resource "azurerm_private_dns_zone" "db_dns" {
#   name                = "laravel-elora.mysql.database.azure.com"
  name                   = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}
resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
  name                  = "db-dns-link"
  private_dns_zone_name = azurerm_private_dns_zone.db_dns.name
  virtual_network_id    = azurerm_virtual_network.VNET_terraform.id
  resource_group_name   = var.resource_group_name
  registration_enabled  = false
}

# # Wait 30 seconds after the subnet is modified/created
# resource "time_sleep" "wait_30_seconds" {
#   depends_on = [azurerm_subnet.appservice_subnet]
#   create_duration = "30s"
# }

# # Link the Main App ONLY after the timer finishes
# resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
#   app_service_id = var.app_service_id
#   subnet_id      = azurerm_subnet.appservice_subnet.id
  
#   depends_on = [time_sleep.wait_30_seconds]
# }

# # Link the Staging Slot after the Main App is done
# resource "azurerm_app_service_slot_virtual_network_swift_connection" "staging_vnet" {
#   app_service_id = var.app_service_id
#   slot_name      = var.slot_name
#   subnet_id      = azurerm_subnet.appservice_subnet.id
  
#   depends_on = [azurerm_app_service_virtual_network_swift_connection.vnet_integration]
# }

