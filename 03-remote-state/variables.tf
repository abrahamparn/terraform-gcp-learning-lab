variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "The Google Cloud region where regional resources will be created."
  type        = string
  default     = "asia-southeast2"
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "remote-state-network"
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "remote-state-subnet"
}

variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.21.0.0/24"
}