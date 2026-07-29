# Azure reference path. Auth via ambient credentials (az login / workload
# identity) — never in code.

terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.30"
    }
  }
}

provider "azurerm" {
  features {}
}

module "substrate" {
  source              = "../../modules/azure-substrate"
  name                = var.name
  environment         = var.environment
  location            = var.location
  network_cidr        = var.network_cidr
  node_subnet_cidr    = var.node_subnet_cidr
  allowed_admin_cidrs = var.allowed_admin_cidrs
}
