# Remote state backend (Azure Storage). Create the storage account/container
# once, out of band, then initialise with partial config:
#
#   terraform init \
#     -backend-config="resource_group_name=rg-tfstate" \
#     -backend-config="storage_account_name=<globally-unique>" \
#     -backend-config="container_name=tfstate" \
#     -backend-config="key=fleet-dev.tfstate"
#
# State is where the generated DB password lives, so the storage account must
# be private, encrypted (default) and access-controlled. Leave the block empty
# to supply values at init time and keep them out of git.
terraform {
  backend "azurerm" {}
}
