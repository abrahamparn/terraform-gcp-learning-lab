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
    error_message = "Region must be one of:  asia-southeast2, asia-southeast1, or us-central1."
  }
}

variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

variable "network_name" {
  description = "Base name of the vpc network"
  type        = string
  default     = "network-module"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."
  }
}

variable "subnets" {
  description = "Map of subnets to create inside the vpc."
  type = map(object({
    cidr_range = string
    region     = optional(string)
  }))

  # Validation 1: Enforce strict naming conventions
  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key))
    ])
    error_message = "Enforce strict naming conventions"
  }

  # Ensure CIDR blocks are valid networks
  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(cidrhost(subnet.cidr_range, 0))
    ])

    error_message = "each cidr_range must be a valid CIDR block."
  }

  # Restrict regional deployment
  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      subnet.region == null ? true : contains(["asia-southeast2", "asia-southeast1", "us-central1"], subnet.region)
    ])
    error_message = "If specified, the subnet region must be one of: asia-southeast2, asia-southeast1, or us-central1."
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



variable "vm_name" {
  description = "The name of the compute engine vm"
  type        = string
  default     = "module-output-vm"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.vm_name))
    error_message = "VM name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number"
  }
}

variable "vm_machine_type" {
  description = "The machine type for the compute engine vm"
  type        = string
  default     = "e2-micro"
}

variable "vm_zone" {
  description = "The zone where the compute engine VM will be created"
  type        = string
  default     = "asia-southeast2-a"
}


variable "vm_subnet_key" {
  description = "the key of the subnet from the network moduel where the vm should be created"
  type        = string
  default     = "app"

  validation {
    condition     = contains(["app", "db"], var.vm_subnet_key)
    error_message = "vm_subnet_key must be either app or db"
  }
}

variable "vm_tags" {
  description = "Network Tags attached to the VM."
  type        = list(string)
  default     = ["iap-ssh"]
}

