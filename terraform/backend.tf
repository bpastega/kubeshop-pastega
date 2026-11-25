# terraform/backend.tf
terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
  backend "azurerm" {
    use_oidc         = true # login da pipeline via OIDC
    use_azuread_auth = true # acesso ao blob por RBAC, sem access key
    # resource_group_name, storage_account_name, container_name e key
    # são passados em "terraform init -backend-config=..."
  }
}
