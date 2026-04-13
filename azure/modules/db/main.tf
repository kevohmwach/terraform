resource "azurerm_mysql_flexible_server" "db_server_flex_laravel" {
  name                   = "laravel-db-server-flex"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.laravel_credentials.db.admin_user
  # administrator_password = var.laravel_credentials.db.admin_pass
  administrator_password = var.random_password_db_admin_pass # Use the random password generated in the security module
  # sku_name               = "B_Standard_B1s"    # Smallest burstable tier
  sku_name               = "B_Standard_B2s"
  version                = "8.0.21"
  zone = "1"

  # This forces the server to wait for whatever is passed into that variable
  depends_on = [var.private_dns_vnet_link_id]

  # NETWORK CONFIG (The Secure Part)
  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = var.private_dns_zone_id

  storage {
    size_gb = 20
    iops    = 360 # Standard
  }

  # maintenance_window {
  #   day_of_week  = 0
  #   start_hour   = 2 # 2 AM on Sunday for patches
  #   start_minute = 0
  # }
}
//*


# # 2. The Database Connection Host (FQDN)
# output "db_host" {
#   value       = azurerm_mysql_flexible_server.db_server_flex_laravel.fqdn
#   description = "Use this in MySQL Workbench or your .env file"
# }

# 3. Your IP (For verification)
# output "detected_public_ip" {
#   value = local.current_ip
#   description = "The IP address that has been whitelisted in the firewall"
# }

resource "azurerm_mysql_flexible_database" "laravel_db" {
  name                = "laravel_app_db"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db_server_flex_laravel.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
resource "azurerm_mysql_flexible_database" "staging_laravel_db" {
  name                = "laravel_app_db_staging"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.db_server_flex_laravel.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}
# Use firewall rules when not i VNET, or for debugging. Comment out in production for better security.
# resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
#   name                = "allow-azure-internal"
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_flexible_server.db_server_flex_laravel.name
#   start_ip_address    = "0.0.0.0"
#   end_ip_address      = "0.0.0.0"
# }

resource "azurerm_mysql_flexible_server" "replica" {
  name                 = "mysql-elara-replica"
  resource_group_name  = var.resource_group_name
  location             = var.location # Or a different zone for HA
  
  create_mode          = "Replica"
  source_server_id     = azurerm_mysql_flexible_server.db_server_flex_laravel.id
  
  # Replicas usually don't need high-availability enabled on themselves
  # because the Master-Replica relationship IS the HA strategy.
  sku_name             = "B_Standard_Bms" 
  
  delegated_subnet_id = var.db_subnet_id
  private_dns_zone_id = var.private_dns_zone_id
}

# You will also need to add the VNet rule for the replica!
resource "azurerm_mysql_flexible_server_configuration" "replica_config" {
  # ... configurations like timezone or character sets if needed
}