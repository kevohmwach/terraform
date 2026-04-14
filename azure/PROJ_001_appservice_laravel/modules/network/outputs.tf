output "appservice_subnet_id" {
  value = azurerm_subnet.appservice_subnet.id
}
output "db_subnet_id" {
  value = azurerm_subnet.db_subnet.id
}
output "private_dns_zone_id" {
  value = azurerm_private_dns_zone.db_dns.id
}
output "private_dns_vnet_link_id" {
  value = azurerm_private_dns_zone_virtual_network_link.dns_link.id
}
output "vnet_id" {
  value = azurerm_virtual_network.VNET_terraform.id
}