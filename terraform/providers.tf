# terraform/providers.tf
provider "azurerm" {
  features {}
  use_oidc = true
}
