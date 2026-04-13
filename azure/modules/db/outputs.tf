# 2. The Database Connection Host (FQDN)
output "db_host" {
  value       = azurerm_mysql_flexible_server.db_server_flex_laravel.fqdn
}
output "db_server_id" {
  value       = azurerm_mysql_flexible_server.db_server_flex_laravel.id
}
output "production_db_name" {
  value       = azurerm_mysql_flexible_database.laravel_db.name
}
output "staging_db_name" {
  value       = azurerm_mysql_flexible_database.staging_laravel_db.name
}
