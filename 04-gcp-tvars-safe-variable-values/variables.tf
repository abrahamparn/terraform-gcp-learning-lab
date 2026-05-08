variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "The project variable must not be empty."
  }
}

variable "region" {
  description = "The Google Cloud region where regional resources will be created."
  type        = string
  default     = "asia-southeast2"

  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "Region must be one of: asia-southeast2, asia-southeast1, or us-central1."
  }
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
  default     = "tfvars-network"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."
  }
}

variable "subnet_name" {
  description = "Base name of the subnet."
  type        = string
  default     = "tfvars-subnet"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.subnet_name))
    error_message = "Subnet name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."
  }
}

variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.30.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr_range, 0))
    error_message = "Subnet CIDR range must be a valid CIDR block, for example 10.30.0.0/24."
  }
}