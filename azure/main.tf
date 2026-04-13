terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20" 
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Define Constant variables that can't be changed at runtime
# locals.region
# Automatically fetches the public IP of the machine running Terraform
# data "http" "my_ip" {
#   url = "https://ifconfig.me"
# }
# locals {
#   # region = "West Europe"
#   # current_ip = chomp(data.http.my_ip.response_body)
#   common_app_settings = {
#     "APP_KEY" = var.laravel_credentials.env.appkey
#     "DB_CONNECTION" = "mysql"
#     "DB_HOST" = azurerm_mysql_flexible_server.db_server_flex_laravel.fqdn
#     "DB_PORT" = "3306"
#     "MYSQL_ATTR_SSL_CA" = "/home/site/wwwroot/certs/DigiCertGlobalRootG2.crt.pem"
#     "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
#     "APP_DEBUG"     = "true"
#     "LOG_STACK" = "single,insights"
#     "SCM_DO_BUILD_DURING_DEPLOYMENT" = "false"
#     "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.appinsights.instrumentation_key
#     "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
#     "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
#   }
# }

provider "azurerm" {
  features {
    application_insights {
      # This prevents the "Failure Anomalies" rule and 
      # its Action Group from being created automatically.
      disable_generated_rule = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
   }
  }
}

data "azurerm_client_config" "current" {}

# output "debug_tenant_id" {
#   value = data.azurerm_client_config.current.tenant_id
# }

# output "debug_subscription_id" {
#   value = data.azurerm_client_config.current.subscription_id
# }

resource "azurerm_resource_group" "RG_app_service" {
    name = "app-service-rg"
    location = var.prod_location
}
//*
# resource "azurerm_virtual_network" "VNET_terraform" {
#   name                = "terraform-vnet"
#   address_space       = [var.addr_space]
#   location            = azurerm_resource_group.RG_app_service.location
#   resource_group_name = azurerm_resource_group.RG_app_service.name
# }

# resource "azurerm_subnet" "SUBNET_prod_subnet" {
#   name                 = "production-subnet"
#   resource_group_name  = azurerm_resource_group.RG_app_service.name
#   virtual_network_name = azurerm_virtual_network.VNET_terraform.name
#   address_prefixes     = [var.prod_subnet_prefixes]
# }
# resource "azurerm_subnet" "db_subnet" {
#   name                 = "db-subnet"
#   resource_group_name  = azurerm_resource_group.RG_app_service.name
#   virtual_network_name = azurerm_virtual_network.VNET_terraform.name
#   address_prefixes     = [var.db_subnet_prefixes]
#   service_endpoints    = ["Microsoft.Storage"]

#   # Delegate this subnet specifically to MySQL Flexible Server
#   delegation {
#     name = "mysql_delegation"
#     service_delegation {
#       name    = "Microsoft.DBforMySQL/flexibleServers"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
#     }
#   }
# }

# resource "azurerm_subnet" "appservice_subnet" {
#   name                 = "appservice-subnet"
#   resource_group_name  = azurerm_resource_group.RG_app_service.name
#   virtual_network_name = azurerm_virtual_network.VNET_terraform.name
#   address_prefixes     = [var.appservice_subnet_prefixes]
#   # service_endpoints    = ["Microsoft.Storage"]

#   # Delegate this subnet specifically to MySQL Flexible Server
#   delegation {
#     name = "webapp_delegation"
#     service_delegation {
#       name    = "Microsoft.Web/serverFarms"
#       actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
#     }
#   }
# }
# # Create a Private DNS Zone (So app can find DB by name)
# resource "azurerm_private_dns_zone" "db_dns" {
#   # name                = "laravel-elora.mysql.database.azure.com"
#   name                   = "privatelink.mysql.database.azure.com"
#   resource_group_name = azurerm_resource_group.RG_app_service.name
# }
# resource "azurerm_private_dns_zone_virtual_network_link" "dns_link" {
#   name                  = "db-dns-link"
#   private_dns_zone_name = azurerm_private_dns_zone.db_dns.name
#   virtual_network_id    = azurerm_virtual_network.VNET_terraform.id
#   resource_group_name   = azurerm_resource_group.RG_app_service.name
#   registration_enabled  = false
# }

# resource "azurerm_service_plan" "app_service_plan_laravel" {
#   name                = "laravel-appserviceplan"
#   resource_group_name = azurerm_resource_group.RG_app_service.name
#   location            = azurerm_resource_group.RG_app_service.location
#   os_type             = "Linux"
#   # sku_name            = "B1" 
#   # sku_name            = "S1" # Allow adding slots for staging/blue-green deployments
#   sku_name            = "P1v2" 
# }



# resource "azurerm_linux_web_app" "Webapp_Laravel" {
#   name                = "laravel-webapp-elora"
#   resource_group_name = azurerm_resource_group.RG_app_service.name
#   location            = azurerm_resource_group.RG_app_service.location
#   service_plan_id     = azurerm_service_plan.app_service_plan_laravel.id
#   public_network_access_enabled = true # Defaults to true

#   tags = {
#     # This specific tag format tells the Azure Portal to show 
#     # the Application Insights menu on the left sidebar.
#     "hidden-link:${azurerm_application_insights.appinsights.id}" = "Resource"
#   }

# site_config {
#     application_stack {
#       php_version = "8.2"
#     }

#     # We chain the commands: 
#     # 1. Fix permissions for storage/cache
#     # 2. Update Nginx root to /public
#     # 3. Run migrations with --force
#     # 4. Reload Nginx to apply changes
#     # app_command_line = <<-EOT
#     #   chmod -R 775 /home/site/wwwroot/storage /home/site/wwwroot/bootstrap/cache && 
#     #   sed -i "s|root /home/site/wwwroot;|root /home/site/wwwroot/public;|g" /etc/nginx/sites-available/default && 
#     #   php /home/site/wwwroot/artisan migrate --force && 
#     #   service nginx reload
#     # EOT
#     # app_command_line = <<-EOT
#     #   chmod -R 775 /home/site/wwwroot/storage /home/site/wwwroot/bootstrap/cache &&  
#     #   service nginx reload
#     # EOT
#     app_command_line = "/home/site/wwwroot/appservice_files/startup-command.sh"
#   }

#   app_settings = merge(local.common_app_settings, {
#     "APP_ENV" = "Production"
#     "APP_NAME" = "Elara on App Service - Laravel Sample"
#     "APP_URL" = "http://laravel-webapp-elora.azurewebsites.net"
#     "DB_DATABASE" = azurerm_mysql_flexible_database.laravel_db.name
#     "DB_USERNAME" = azurerm_mysql_flexible_server.db_server_flex_laravel.administrator_login
#     "DB_PASSWORD" = azurerm_mysql_flexible_server.db_server_flex_laravel.administrator_password
#   })

#   # CRITICAL: This makes the settings "Sticky"
#   # Even if you SWAP, the Prod slot keeps 'production' values
#   sticky_settings {
#     app_setting_names = ["DB_DATABASE", "APP_ENV"]
#   }

#   # Mount File share for persistent storage of uploads (simulate "local" disk in Laravel)
#   storage_account {
#     access_key   = azurerm_storage_account.storage_account.primary_access_key
#     account_name = azurerm_storage_account.storage_account.name
#     name         = "uploads-mount"
#     share_name   = azurerm_storage_share.uploads.name
#     type         = "AzureFiles"
#     mount_path   = "/home/site/wwwroot/storage/app/uploads"
#   }
  
# }
# # Link webapp to vnet for secure DB connectivity (Private Endpoint alternative)
#   resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
#   app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
#   subnet_id      = azurerm_subnet.appservice_subnet.id  # A different subnet in the same VNet
# }
# # The Staging Slot (Child)
# resource "azurerm_linux_web_app_slot" "staging" {
#   name = "laravel-app-staging"
#   app_service_id = azurerm_linux_web_app.Webapp_Laravel.id
#   site_config {
#     application_stack {
#       php_version = "8.2"
#     }
#     app_command_line = "/home/site/wwwroot/appservice_files/startup-command.sh"
#   }
#   app_settings = merge(local.common_app_settings, {
#     "APP_ENV" = "Staging"
#     "APP_NAME" = "Staging -Elara on App Service - Laravel Sample"
#     "APP_URL" = "https://laravel-webapp-elora-laravel-app-staging.azurewebsites.net"
#     "DB_DATABASE" = azurerm_mysql_flexible_database.staging_laravel_db.name
#     "DB_USERNAME" = azurerm_mysql_flexible_server.db_server_flex_laravel.administrator_login
#     "DB_PASSWORD" = azurerm_mysql_flexible_server.db_server_flex_laravel.administrator_password
# })
# }

# resource "azurerm_source_control_token" "github" {
#   type  = "GitHub"
#   token = var.laravel_credentials.pat.github_pat
# }

# resource "azurerm_app_service_source_control" "github" {
#   app_id   = azurerm_linux_web_app.Webapp_Laravel.id
#   repo_url = var.laravel_credentials.repo.laravel_app_repo
#   branch   = var.laravel_credentials.branch.laravel_app_branch

#   # Ensure this depends on the token being set first
#   depends_on = [azurerm_source_control_token.github]
#   # For public repos, use this. 
#   # For private, you'll need to set up a GitHub token in the Portal once.
# #   manual_integration = true 
# }
//*/
# resource "azurerm_mysql_flexible_server" "db_server_flex_laravel" {
#   name                   = "laravel-db-server-flex"
#   resource_group_name    = azurerm_resource_group.RG_app_service.name
#   location               = azurerm_resource_group.RG_app_service.location
#   administrator_login    = var.laravel_credentials.db.admin_user
#   administrator_password = var.laravel_credentials.db.admin_pass
#   # sku_name               = "B_Standard_B1s"    # Smallest burstable tier
#   sku_name               = "B_Standard_B2s"
#   version                = "8.0.21"
#   zone = "1"

#   # NETWORK CONFIG (The Secure Part)
#   delegated_subnet_id = azurerm_subnet.db_subnet.id
#   private_dns_zone_id = azurerm_private_dns_zone.db_dns.id

#   storage {
#     size_gb = 20
#     iops    = 360 # Standard
#   }

#   # maintenance_window {
#   #   day_of_week  = 0
#   #   start_hour   = 2 # 2 AM on Sunday for patches
#   #   start_minute = 0
#   # }
# }
# //*


# # # 2. The Database Connection Host (FQDN)
# # output "db_host" {
# #   value       = azurerm_mysql_flexible_server.db_server_flex_laravel.fqdn
# #   description = "Use this in MySQL Workbench or your .env file"
# # }

# # 3. Your IP (For verification)
# # output "detected_public_ip" {
# #   value = local.current_ip
# #   description = "The IP address that has been whitelisted in the firewall"
# # }

# resource "azurerm_mysql_flexible_database" "laravel_db" {
#   name                = "laravel_app_db"
#   resource_group_name = azurerm_resource_group.RG_app_service.name
#   server_name         = azurerm_mysql_flexible_server.db_server_flex_laravel.name
#   charset             = "utf8mb4"
#   collation           = "utf8mb4_unicode_ci"
# }
# resource "azurerm_mysql_flexible_database" "staging_laravel_db" {
#   name                = "laravel_app_db_staging"
#   resource_group_name = azurerm_resource_group.RG_app_service.name
#   server_name         = azurerm_mysql_flexible_server.db_server_flex_laravel.name
#   charset             = "utf8mb4"
#   collation           = "utf8mb4_unicode_ci"
# }
# # resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
# #   name                = "allow-azure-internal"
# #   resource_group_name = azurerm_resource_group.RG_app_service.name
# #   server_name         = azurerm_mysql_flexible_server.db_server_flex_laravel.name
# #   start_ip_address    = "0.0.0.0"
# #   end_ip_address      = "0.0.0.0"
# # }
//*/



# # Implementing  observability stack
# # 1. Create the Storage (Log Analytics)
# resource "azurerm_log_analytics_workspace" "log_analytics_wksp" {
#   name                = "laravel-log-workspace"
#   location            = azurerm_resource_group.RG_app_service.location
#   resource_group_name = azurerm_resource_group.RG_app_service.name
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
# }

# # 2. Create the APM (Application Insights)
# resource "azurerm_application_insights" "appinsights" {
#   name                = "laravel-app-insights"
#   location            = azurerm_resource_group.RG_app_service.location
#   resource_group_name = azurerm_resource_group.RG_app_service.name
#   workspace_id        = azurerm_log_analytics_workspace.log_analytics_wksp.id
#   application_type    = "web"
#   # Force Terraform to wait until the Workspace is fully confirmed
#   depends_on = [azurerm_log_analytics_workspace.log_analytics_wksp]
# }

# # 3. Connect to Web App via App Settings using ENV variables (see above in azurerm_linux_web_app resource)

# # Send Nginx logs and Startup Script logs to Log Analytics for troubleshooting
# resource "azurerm_monitor_diagnostic_setting" "webapp_logs" {
#   name                       = "web-app-logs-to-log-analytics"
#   target_resource_id         = azurerm_linux_web_app.Webapp_Laravel.id
#   log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics_wksp.id

#   enabled_log {
#     category = "AppServiceConsoleLogs" # Captures your .sh script output
#   }
#   enabled_log {
#     category = "AppServiceHTTPLogs"    # Captures Nginx traffic
#   }
# }


# # Implementing Persistent storage for Laravel (Azure Files)
# resource "azurerm_storage_account" "storage_account" {
#   name                     = "laravelfilestorage"
#   resource_group_name      = azurerm_resource_group.RG_app_service.name
#   location                 = azurerm_resource_group.RG_app_service.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   https_traffic_only_enabled = true
#   min_tls_version           = "TLS1_2"
# }
# # 2. The File Share (The Logical Partition)
# resource "azurerm_storage_share" "uploads" {
#   name                 = "laravel-uploads"
#   storage_account_id = azurerm_storage_account.storage_account.id
#   quota                = 50 # Limit to 50GB
# }
# # Lock down the STORAGE ACCOUNT Firewall
# resource "azurerm_storage_account_network_rules" "lockdown" {
#   storage_account_id = azurerm_storage_account.storage_account.id

#   default_action             = "Deny" # BLOCK EVERYTHING ELSE
#   virtual_network_subnet_ids = [azurerm_subnet.db_subnet.id] # ALLOW ONLY THE APP
  
#   # Optional: Allow your office IP so you can still see files in the portal
#   # ip_rules = ["YOUR_OFFICE_IP"] 
# }


# Custom Domain and SSL with Azure Front Door 
# # 1. Bind the Custom Domain
# resource "azurerm_app_service_custom_hostname_binding" "gradestar_domain" {
#   hostname            = "www.gradestar.com"
#   app_service_name    = azurerm_linux_web_app.example.name
#   resource_group_name = "app-service-rg"
# }

# # 2. Create the Free Managed Certificate
# resource "azurerm_app_service_managed_certificate" "gradestar_cert" {
#   custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.gradestar_domain.id
# }

# # 3. Enable HTTPS (SNI)
# resource "azurerm_app_service_certificate_binding" "gradestar_ssl" {
#   hostname_binding_id = azurerm_app_service_custom_hostname_binding.gradestar_domain.id
#   certificate_id      = azurerm_app_service_managed_certificate.gradestar_cert.id
#   ssl_state           = "SniEnabled"
# }









# resource "azurerm_role_assignment" "app_to_kv" {
#   scope                = module.security.key_vault_id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = module.appservice.app_service_principal_id
# }
# resource "azurerm_role_assignment" "staging_app_to_kv" {
#   scope                = module.security.key_vault_id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = module.appservice.slot_principal_id
# }

# Policy for the APP SERVICE
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = module.security.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.appservice.app_service_principal_id # Passed from app module

  secret_permissions = ["Get", "List"]
}

# Policy for the STAGING SLOT
resource "azurerm_key_vault_access_policy" "staging_slot" {
  key_vault_id = module.security.key_vault_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = module.appservice.slot_principal_id # Passed from app module

  secret_permissions = ["Get", "List"]
}


module "appservice" {
  source = "./modules/appservice"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  production_db_name = module.db.production_db_name
  staging_db_name = module.db.staging_db_name
  db_host = module.db.db_host
  # db_host = "laravel-db-server-flex.privatelink.mysql.database.azure.com"
  storage_account_name = module.storage.storage_account_name
  storage_account_accesskey = module.storage.storage_account_accesskey
  file_share_name = module.storage.file_share_name
  instrumentation_key = module.observability.instrumentation_key
  connection_string = module.observability.connection_string
  appservice_subnet_id = module.network.appservice_subnet_id
  appinsights_id = module.observability.appinsights_id
  key_vault_secret_id_db_password = module.security.key_vault_secret_id_db_password
  custom_domain_name = var.custom_domain_name
  key_vault_secret_id_app_url = module.security.key_vault_secret_id_app_url

  laravel_credentials = {
    pat: {
        github_pat: var.laravel_credentials.pat.github_pat
    }
    repo: {
        laravel_app_repo: var.laravel_credentials.repo.laravel_app_repo
    }
    branch: {
        laravel_app_branch: var.laravel_credentials.branch.laravel_app_branch
    }
    db: {
        admin_user: var.laravel_credentials.db.admin_user, 
        admin_pass: var.laravel_credentials.db.admin_pass
    },

    env:{
        appkey = var.laravel_credentials.env.appkey
    },
}
  
}
module "db" {
  source = "./modules/db"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  db_subnet_id = module.network.db_subnet_id
  private_dns_zone_id = module.network.private_dns_zone_id
  private_dns_vnet_link_id = module.network.private_dns_vnet_link_id
  random_password_db_admin_pass = module.security.random_password_db_admin_pass
  laravel_credentials = {
    db: {
        admin_user: var.laravel_credentials.db.admin_user, 
        admin_pass: var.laravel_credentials.db.admin_pass
    },
  }
  
}

module "network" {
  source = "./modules/network"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  addr_space = var.addr_space
  prod_subnet_prefixes = var.prod_subnet_prefixes
  db_subnet_prefixes = var.db_subnet_prefixes
  appservice_subnet_prefixes = var.appservice_subnet_prefixes
  # app_service_id = module.appservice.app_service_id
  # slot_name = module.appservice.slot_name
  
}
module "identity" {
  source = "./modules/identity"
  # resource_group_name = azurerm_resource_group.RG_app_service.name
  # location = azurerm_resource_group.RG_app_service.location
  # resource_group_id = azurerm_resource_group.RG_app_service.id
  # project_name = var.project_name

}
module "storage" {
  source = "./modules/storage"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  db_subnet_id = module.network.db_subnet_id
  appservice_subnet_id = module.network.appservice_subnet_id
  
}
module "observability" {
  source = "./modules/observability"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  web_app_id = module.appservice.web_app_id
  alert_email         = var.email_address.kelvin
  db_server_id        = module.db.db_server_id
  
}
module "security" {
  source = "./modules/security"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  location            = azurerm_resource_group.RG_app_service.location
  # app_service_principal_id = module.appservice.app_service_principal_id
  # slot_principal_id = module.appservice.slot_principal_id
  project_name = var.project_name
  environment = "devTest"
  db_password = var.laravel_credentials.db.admin_pass
  app_service_subnet_id = module.network.appservice_subnet_id  
  custom_domain_name = var.custom_domain_name
  webapp_default_url = var.webapp_default_url
  custom_domain_enabled = var.custom_domain_enabled
  resource_group_id = azurerm_resource_group.RG_app_service.id
}
module "governance" {
  source = "./modules/governance"
  resource_group_name = azurerm_resource_group.RG_app_service.name
  resource_group_id = azurerm_resource_group.RG_app_service.id
  location            = azurerm_resource_group.RG_app_service.location
  db_server_id = module.db.db_server_id
  vnet_id = module.network.vnet_id
  project_name = var.project_name
  alert_email = var.email_address.kelvin
}


