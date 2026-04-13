output "key_vault_secret_id_db_password" { 
  value = azurerm_key_vault_secret.db_password.versionless_id
  description = "The secret ID of the DB password in Key Vault (without version, for use in App Service configuration)"
}

output "key_vault_secret_id_app_url" { 
  value = azurerm_key_vault_secret.app_url.versionless_id
  description = "The secret ID of the App URL in Key Vault (without version, for use in App Service configuration)"
}
output "random_password_db_admin_pass" { # return the generated password for use in db module
  value = random_password.db_admin_pass.result
  sensitive = true
}
output "key_vault_id" {
  value = azurerm_key_vault.vault.id
}
output "managed_identity_github_client_id" {
  value = azurerm_user_assigned_identity.github_actions.client_id
}