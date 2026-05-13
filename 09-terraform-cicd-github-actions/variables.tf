variable "project" {
  description = "The google cloud project id where resources will be created"
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "The project variable must not be empty."
  }
}

variable "region" {
  description = "Google Cloud region for regional resources."
  type        = string
  default     = "asia-southeast2"

  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "Region must be one of: asia-southeast2, asia-southeast1, us-central"
  }
}

variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of : dev, staging, or prod"
  }
}

variable "network_name" {
  description = "The base name of the network vpc"
  type        = string
  default     = "cicd-network"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Netowkr name must use lowercase letters numbers and hyphens"
  }
}


variable "subnet_name" {
  description = "Base name of the subnet"
  type        = string
  default     = "cicd-subnet"

  validation {
    condition = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.subnet_name))

    error_message = "Subnet name must use lowercase letters numebrs and hyphens"
  }
}

variable "subnet_cidr_range" {
  description = "CIDR range for the subent"
  type        = string
  default     = "10.90.1.0/24"
  validation {
    condition     = can(cidrhost(var.subnet_cidr_range, 0))
    error_message = "subnet_cidr_range must be a valid CIDR block, for example 10.90.1.0/24."
  }
}