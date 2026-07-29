# Substrate only: network, firewall, key, placement. Servers are Cluster
# API's job (CAPH), and everything inside them is GitOps.

resource "hcloud_network" "this" {
  name     = "${var.name}-${var.environment}"
  ip_range = var.network_cidr
  labels = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

resource "hcloud_network_subnet" "nodes" {
  network_id   = hcloud_network.this.id
  type         = "cloud"
  network_zone = var.region
  ip_range     = var.node_subnet_cidr
}

resource "hcloud_placement_group" "control_plane" {
  name = "${var.name}-${var.environment}-cp"
  type = "spread"
  labels = {
    environment = var.environment
    role        = "control-plane"
  }
}

resource "hcloud_ssh_key" "admin" {
  name       = "${var.name}-${var.environment}-admin"
  public_key = var.ssh_public_key
}

resource "hcloud_firewall" "nodes" {
  name = "${var.name}-${var.environment}-nodes"

  rule {
    description = "Kubernetes API from admin networks"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = var.allowed_admin_cidrs
  }

  rule {
    description = "SSH from admin networks"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.allowed_admin_cidrs
  }
}

# Hetzner object storage is S3-compatible but not managed by this provider;
# buckets for Loki/backups are created via the S3 API against
# https://<region>.your-objectstorage.com — documented in the environment
# README rather than half-managed here.
