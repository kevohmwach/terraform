terraform init
terraform plan
terraform plan --refresh-only
terraform apply --auto-approve
terraform destroy
terraform workspace list

terraform state list
terraform state show <resource>

# See outputs
terraform output

# See ouput without applying changes
terraform refresh

# Targetted commands
terraform destroy -target <rourcetype.resourcename>
terraform apply -target <rourcetype.resourcename>

# Apply variables
terraform apply -var "subnet_prefix=10.0.1.0/24"
terraform apply -var-file variables.tfvars