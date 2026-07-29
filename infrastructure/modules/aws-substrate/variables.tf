variable "name" {
  description = "Substrate name; prefixes every resource"
  type        = string
}

variable "environment" {
  description = "Environment label (production, staging)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "network_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b"]
}
