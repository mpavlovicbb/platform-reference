variable "name" {
  description = "Substrate name; prefixes every resource"
  type        = string
}

variable "environment" {
  description = "Environment label (production, staging)"
  type        = string
}

variable "region" {
  description = "Hetzner network zone (eu-central, us-east, us-west)"
  type        = string
  default     = "eu-central"
}

variable "network_cidr" {
  description = "Private network CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_subnet_cidr" {
  description = "Subnet for cluster nodes, within network_cidr"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_admin_cidrs" {
  description = "CIDRs allowed to reach the Kubernetes API and SSH"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "SSH public key material for node access"
  type        = string
}
