################Export Environment variabled#########################

#--------------------------------
#Ubuntu: Export env variables
#-----------------------------------
# export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
# export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"

# Make env variables persistent accross sessions

# echo 'export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"' >> ~/.bashrc
# echo 'export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"' >> ~/.bashrc
# source ~/.bashrc


#--------------------------------
#PowerShell: Export env variables
#-----------------------------------

#     region = "us-east-1"
#     #export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
#     #export AWS_SECRET_KEY="YOUR_SECRET_ACCESS_KEY"

#     #$env:AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
#     #$env:AWS_SECRET_KEY="YOUR_SECRET_ACCESS_KEY"
#     #$env:AWS_DEFAULT_REGION="us-east-1"


#AWS CLI
# provider "aws" {
#     region = "us-east-1"
#     shared_credentials_files = ["/home/user/.aws/credentials.eample.tf"]
# }

#Hard coded credentials
# provider "aws" {
#     region = "us-east-1"
#     access_key = "YOUR_ACCESS_KEY_ID"
#     secret_key = "YOUR_SECRET_ACCESS_KEY"
# }