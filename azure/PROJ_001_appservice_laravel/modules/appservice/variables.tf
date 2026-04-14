# Root variables
variable "project_name" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "location" {
  type = string
}

# App Service Variables
variable "laravel_credentials" {
  type = any
}
variable "custom_domain_name" {
  type = string
}

# db variables
variable "db_host" {
  type = string
}

# variable "kv_db_host_write" {
#   type = string
# }
# variable "kv_db_host_read" {
#   type = string
# }
variable "production_db_name" {
  type = string
}
variable "staging_db_name" {
  type = string
}


# storage variables
variable "storage_account_name" {
  type = string
}
variable "storage_account_accesskey" {
  type = string
}
variable "file_share_name" {
  type = string
}
variable "instrumentation_key" {
  type = string
}
variable "connection_string" {
  type = string
}


# Network variables
variable "appservice_subnet_id" {
  type = string
}

# observability variables
variable "appinsights_id" {
  type = string
}

# security variables 
variable "key_vault_secret_id_db_password" {
  type = string
  description = "DB Password"
}
variable "key_vault_secret_id_app_url" {
  type = string
  description = "App URL"
}

