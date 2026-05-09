variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "The project variable must not be empty."
  }
}

variable "region" {
  description = "Default Google Cloud region for regional resources."
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
  default     = "network-module"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."
  }
}

variable "subnets" {
  description = "Map of subnets to create inside the VPC."
  type = map(object({
    cidr_range = string
    region     = optional(string)
  }))

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key)) &&
      can(cidrhost(subnet.cidr_range, 0))
    ])

    error_message = "Each subnet key must be a valid lowercase name, and each cidr_range must be a valid CIDR block."
  }
}

variable "firewall_rules" {
  description = "Map of ingress firewall rules to create."
  type = map(object({
    description   = optional(string)
    source_ranges = list(string)
    target_tags   = optional(list(string), [])
    allow = list(object({
      protocol = string
      ports    = optional(list(string))
    }))
  }))

  default = {}

  validation {
    condition = alltrue(flatten([
      for rule_name, rule in var.firewall_rules : [
        for source_range in rule.source_ranges :
        can(cidrhost(source_range, 0))
      ]
    ]))

    error_message = "Every firewall source range must be a valid CIDR block."
  }
}