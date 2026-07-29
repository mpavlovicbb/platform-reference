variable "name" {
  description = "Cluster/substrate name"
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "production"
}

variable "region" {
  description = "Hetzner network zone"
  type        = string
  default     = "eu-central"
}

variable "network_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "node_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "allowed_admin_cidrs" {
  description = "Who may reach the API and SSH; never 0.0.0.0/0"
  type        = list(string)
}

variable "ssh_public_key" {
  description = "Admin SSH public key material"
  type        = string
}
