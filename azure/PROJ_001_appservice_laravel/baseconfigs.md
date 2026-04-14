# update local .tfstate
terraform refresh

# Targetted Plan 
terraform plan -target=azurerm_application_insights.appinsights

# See debug logs/errors when applying
export TF_LOG=DEBUG
export TF_LOG=ERROR
terraform apply

# Disable debug Logging
unset TF_LOG

# Create Service Principal
az ad sp create-for-rbac --name "terraformAuth" --role contributor --scopes /subscriptions/<subscription-terraform>

# Log in with Service Principle:
az login --service-principal \
         --username <appId> \
         --password <password> \
         --tenant <tenant>

# List azure locations
az account list-locations --query "[].{Name:name, DisplayName:displayName}" -o table

# See app logs realtime
az webapp log tail --name laravel-webapp-linux --resource-group app-service-rg

# To see the deployment logs specifically
az webapp log deployment list --name laravel-webapp-linux --resource-group app-service-rg

# List all regions that support the Basic (B1) SKU for Linux
az appservice list-locations --sku B1 --linux-workers-enabled --output table

# List all SKUs available in South Africa North
az appservice list-locations --location southafricanorth --output table


# 1. List deleted vaults to confirm it's there
az keyvault list-deleted

# 2. Purge the vault (This permanently deletes it and the secrets inside)
az keyvault purge --name kv-Elara-devTest