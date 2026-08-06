# Remote state backend (Azure Storage). Use a SEPARATE state key (and ideally a
# separate storage account/subscription) from dev for blast-radius isolation.
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate" \
#     -backend-config="storage_account_name=<globally-unique>" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=fleet-prod.tfstate"
terraform {
  backend "azurerm" {}
}
