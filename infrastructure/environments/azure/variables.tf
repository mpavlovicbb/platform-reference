variable "name" {
  type    = string
  default = "platform"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "location" {
  type    = string
  default = "germanywestcentral"
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
  description = "Who may reach the API; never 0.0.0.0/0"
  type        = list(string)
}
