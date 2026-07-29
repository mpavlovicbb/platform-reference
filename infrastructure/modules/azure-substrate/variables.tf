variable "name" {
  description = "Substrate name; prefixes every resource"
  type        = string
}

variable "environment" {
  description = "Environment label (production, staging)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "germanywestcentral"
}

variable "network_cidr" {
  description = "VNet CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_subnet_cidr" {
  description = "Subnet for cluster nodes, within network_cidr"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_admin_cidrs" {
  description = "CIDRs allowed to reach the Kubernetes API"
  type        = list(string)
}
