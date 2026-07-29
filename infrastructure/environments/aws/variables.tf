variable "name" {
  type    = string
  default = "platform"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "network_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}
