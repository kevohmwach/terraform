locals {
  common_app_settings = {
    "APP_KEY" = var.laravel_credentials.env.appkey
    "DB_CONNECTION" = "mysql"
    "DB_HOST" = var.db_host
    "DB_PORT" = "3306"
    "DB_USERNAME" = var.laravel_credentials.db.admin_user
    "DB_PASSWORD" = var.laravel_credentials.db.admin_pass
    "DB_PASSWORD" = "@Microsoft.KeyVault(SecretUri=${var.key_vault_secret_id_db_password})"
    "MYSQL_ATTR_SSL_CA" = "/home/site/wwwroot/certs/DigiCertGlobalRootG2.crt.pem"
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "APP_DEBUG"     = "true"
    "LOG_STACK" = "single,insights"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    # Tells the app to use Azure's internal DNS resolver that sits inside your VNet
    "WEBSITE_DNS_SERVER"     = "168.63.129.16"
    # "WEBSITE_VNET_ROUTE_ALL" = "1"  # Obsolete
  }
}

# Wait 30 seconds after the subnet is modified/created
resource "time_sleep" "wait_30_seconds" {
  depends_on = [var.appservice_subnet_id]
  create_duration = "30s"
}

resource "azurerm_service_plan" "app_service_plan_laravel" {
  name                = "laravel-appserviceplan"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
#   sku_name            = "B1" 
  sku_name            = "S1" # Allow adding slots for staging/blue-green deployments
  # sku_name            = "P1v2" 
}



resource "azurerm_linux_web_app" "Webapp_Laravel" {
  name                = "laravel-webapp-elora"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_service_plan_laravel.id
  public_network_access_enabled = true # Defaults to true
  # Force HTTPS only
  https_only = true


  # tags = {
  #   # This specific tag format tells the Azure Portal to show 
  #   # the Application Insights menu on the left sidebar.
  #   # "hidden-link:${var.appinsights_id}" = "Resource"
  # }

site_config {
    application_stack {
      php_version = "8.2"
    }

    app_command_line = "/home/site/wwwroot/appservice_files/startup-command.sh"
    vnet_route_all_enabled = true
    # If it returns 500 or times out, Azure removes the instance from the LB.
    health_check_path                 = "/api/health"
    # Valid values are between 2 and 10. 10 is the standard default for most SRE setups.
    health_check_eviction_time_in_min = 10
    # Minimum TLS version (SRE Gold Standard is 1.2)
    minimum_tls_version = "1.2"
    
    # HTTP2 for better performance
    http2_enabled = true
    
  }

  app_settings = merge(local.common_app_settings, {
    "APP_ENV" = "Production"
    "APP_NAME" = "Elara on App Service - Laravel Sample"
    # "APP_URL" = "http://laravel-webapp-elora.azurewebsites.net"
    "APP_URL"     = "@Microsoft.KeyVault(SecretUri=${var.key_vault_secret_id_app_url})"
    "DB_DATABASE" = var.production_db_name
  })

  # CRITICAL: This makes the settings "Sticky"
  # Even if you SWAP, the Prod slot keeps 'production' values
  sticky_settings {
    app_setting_names = ["DB_DATABASE", "APP_ENV", "APP_NAME", "APP_URL", "DB_HOST", "WEBSITE_DNS_SERVER"]
  }

  lifecycle {
    ignore_changes = [
      virtual_network_subnet_id, # vnet connection to be done as a resource of its own to control timing and dependencies
      tags["hidden-link: /app-insights-resource-id"], # Ignore ONLY this specific key
    ]
  }
  identity {
    type = "SystemAssigned"
  }

  # Mount File share for persistent storage of uploads (simulate "local" disk in Laravel)
  storage_account {
    access_key   = var.storage_account_accesskey
    account_name = var.storage_account_name
    name         = "uploadsmount"
    share_name   = var.file_share_name
    type         = "AzureFiles"
    mount_path   = "/home/site/wwwroot/storage/app"
  }
  
}
# Link webapp to vnet for secure DB connectivity (Private Endpoint alternative)
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
  subnet_id      = var.appservice_subnet_id  # A different subnet in the same VNet
  depends_on = [time_sleep.wait_30_seconds] # Ensure the subnet is fully ready before connecting
}
# The Staging Slot (Child)
resource "azurerm_linux_web_app_slot" "staging" {
  name = "laravel-app-staging"
  app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
  # Force HTTPS only
  https_only = true

  site_config {
    application_stack {
      php_version = "8.2"
    }
    app_command_line = "/home/site/wwwroot/appservice_files/startup-command.sh"
    vnet_route_all_enabled = true
    # If it returns 500 or times out, Azure removes the instance from the LB.
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 10
     # Minimum TLS version (SRE Gold Standard is 1.2)
    minimum_tls_version = "1.2"
  }
  app_settings = merge(local.common_app_settings, {
    "APP_ENV" = "Staging"
    "APP_NAME" = "Staging -Elara on App Service - Laravel Sample"
    "APP_URL" = "https://laravel-webapp-elora-laravel-app-staging.azurewebsites.net"
    "DB_DATABASE" = var.staging_db_name
})

lifecycle {
    ignore_changes = [
      virtual_network_subnet_id, # vnet connection to be done as a resource of its own to control timing and dependencies
      tags["hidden-link: /app-insights-resource-id"], # Ignore ONLY this specific key
    ]
  }
  identity {
    type = "SystemAssigned"
  }
}

# Connect the SLOT to the VNet
resource "azurerm_app_service_slot_virtual_network_swift_connection" "staging_vnet" {
  app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
  slot_name      = azurerm_linux_web_app_slot.staging.name
  subnet_id      = var.appservice_subnet_id 
  # Ensure the main app is fully integrated before touching the slot
  depends_on = [azurerm_app_service_virtual_network_swift_connection.vnet_integration]
}


# Using OIDC for GitHub Actions instead of  source control tocken
# resource "azurerm_source_control_token" "github" {
#   type  = "GitHub"
#   token = var.laravel_credentials.pat.github_pat
# }

# resource "azurerm_app_service_source_control" "github" {
#   app_id   = azurerm_linux_web_app.Webapp_Laravel.id
#   # repo_url = var.laravel_credentials.repo.laravel_app_repo
#   repo_url = replace(var.laravel_credentials.repo.laravel_app_repo, ".git", "")
#   branch   = var.laravel_credentials.branch.laravel_app_branch

#   depends_on = [azurerm_source_control_token.github]
#   # manual_integration = true 
# }

# Custom Domain and SSL with Azure Front Door 
# 1. Bind the Custom Domain
resource "azurerm_app_service_custom_hostname_binding" "custom_domain" {
  hostname            = var.custom_domain_name
  app_service_name    = azurerm_linux_web_app.Webapp_Laravel.name
  resource_group_name = var.resource_group_name
}

# 2. Create the Free Managed Certificate
resource "azurerm_app_service_managed_certificate" "custom_domain_cert" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom_domain.id
}

# 3. Enable HTTPS (SNI)
resource "azurerm_app_service_certificate_binding" "custom_domain_ssl" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.custom_domain.id
  certificate_id      = azurerm_app_service_managed_certificate.custom_domain_cert.id
  ssl_state           = "SniEnabled"
}

