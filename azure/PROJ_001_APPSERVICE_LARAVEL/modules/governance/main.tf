# # Lock the Resource Group to prevent accidental deletion of the whole project
# resource "azurerm_management_lock" "rg_lock" {
#   name       = "project-level-lock"
#   scope      = var.resource_group_id
#   lock_level = "CanNotDelete"
#   notes      = "This Resource Group contains Elara production resources. Deletion is prohibited via Terraform."
# }

# # Optional: Specifically lock the Database to be extra safe
# resource "azurerm_management_lock" "db_lock" {
#   name       = "database-protection-lock"
#   scope      = var.db_server_id 
#   lock_level = "CanNotDelete"
#   notes      = "Critical Database: Cannot be deleted without manually removing this lock."
# }
# resource "azurerm_management_lock" "vnet_lock" {
#   name       = "vnet-critical-lock"
#   scope      = var.vnet_id
#   lock_level = "CanNotDelete"
#   notes      = "Preventing VNet deletion to protect delegated subnets."
# }

resource "azurerm_consumption_budget_resource_group" "elara_budget" {
  name              = "budget-${var.project_name}"
  resource_group_id = var.resource_group_id
  amount            = 10 # Your monthly limit in USD
  time_grain        = "Monthly"

  time_period {
    start_date = "2026-04-01T00:00:00Z" # Must be 1st of the month
  }

  notification {
    enabled   = true
    threshold = 50.0 # Alert at $5
    operator  = "GreaterThan"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled   = true
    threshold = 100.0 # Alert at $10
    operator  = "GreaterThan"
    contact_emails = [var.alert_email]
  }
}