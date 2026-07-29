# Hetzner: the primary non-hyperscaler path. Auth via HCLOUD_TOKEN env var —
# no credentials in code, state, or CI.

terraform {
  required_version = ">= 1.9"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.68"
    }
  }
  # State backend intentionally unset in the reference: pick your own
  # (S3-compatible object storage works against Hetzner's endpoints).
}

provider "hcloud" {}

module "substrate" {
  source              = "../../modules/hetzner-substrate"
  name                = var.name
  environment         = var.environment
  region              = var.region
  network_cidr        = var.network_cidr
  node_subnet_cidr    = var.node_subnet_cidr
  allowed_admin_cidrs = var.allowed_admin_cidrs
  ssh_public_key      = var.ssh_public_key
}
