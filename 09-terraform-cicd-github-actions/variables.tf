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


variable "subnets" {
  description = "Map of subnets to create inside the VPC."

  type = map(object({
    cidr_range = string
    region     = optional(string)
  }))

  default = {
    app = {
      cidr_range = "10.90.1.0/24"
    }
    db = {
      cidr_range = "10.90.2.0/24"
    }
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key))
    ])
    error_message = "Each subnet key must use lowercase letters, numbers, and hyphens."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(cidrhost(subnet.cidr_range, 0))
    ])
    error_message = "Each cidr_range must be a valid CIDR block, for example 10.90.1.0/24."
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      subnet.region == null ? true : contains(["asia-southeast2", "asia-southeast1", "us-central1"], subnet.region)
    ])
    error_message = "If specified, each subnet region must be one of: asia-southeast2, asia-southeast1, or us-central1."
  }
}
