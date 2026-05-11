variable "environment" {
  description = "Environment name used for resource naming"
  type        = string
}

variable "region" {
  description = "Region where Cloud Router and Cloud NAT will be created."
  type        = string
}


variable "network_self_link" {
  description = "Self-link of the VPC network."
  type        = string
}

variable "router_name" {
  description = "Base name of the router for the NAT"
  type        = string
  default     = "nat-router"
}

variable "nat_name" {
  description = "Base name for the cloud NAT Gateway"
  type        = string
  default     = "nat-gateway"
}