output "resource_group" { value = azurerm_resource_group.rg.name }
output "nsg_app_name" { value = azurerm_network_security_group.app.name }
output "app_public_ip" { value = azurerm_public_ip.app.ip_address }
output "app_fqdn" { value = azurerm_public_ip.app.fqdn }
output "app_private_ip" { value = local.app_ip }
output "db_private_ip" { value = local.db_ip }
output "admin_username" { value = var.admin_username }
