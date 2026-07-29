# AWS reference path. Auth via ambient credentials (SSO/role) — never in code.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "substrate" {
  source             = "../../modules/aws-substrate"
  name               = var.name
  environment        = var.environment
  region             = var.region
  network_cidr       = var.network_cidr
  availability_zones = var.availability_zones
}
