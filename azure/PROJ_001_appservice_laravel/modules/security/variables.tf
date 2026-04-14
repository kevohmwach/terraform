# Global Variables
variable "resource_group_name" {
  type = string
}
variable "resource_group_id" {
  type = string
}
variable "location" {
  type = string
}
variable "app_service_subnet_id" {
  type = string
}
variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "db_password" {
  type = string
}

# App Service Variables
# variable "app_service_principal_id" {
#   type = string
# }
# variable "slot_principal_id" { 
#   type = string
# }
variable "custom_domain_name" {
  type = string
}
variable "webapp_default_url" {
  type = string
}
variable "custom_domain_enabled" {
  type = bool
  default = false
}

variable "db_host_write" {
  type = string
}

variable "db_host_read" {
  type = string
}
variable "random_generated_db_admin_pass" {
  type = string
}
