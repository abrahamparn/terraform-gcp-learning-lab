variable "project" {
  description = "The google cloud project id where resrouces will be created."
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "the project variable msut not be empty"
  }
}

variable "region" {
  description = "Default google cloud region for regional resoruces"
  type        = string
  default     = "asia-southeast2"
  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "region must be one of asia-southeast2, asia-southeast1, or us-central1."

  }
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod"
  }
}

variable "admin_principal" {
  description = "IAM Principal allowed to access the private VM through IAP and OS Login Example: user:name@example.com"
  type        = string
  validation {
    condition     = can(regex("^(user|group|serviceAccount):.+", var.admin_principal))
    error_message = "admin_principal must start with user:, group;, or serviceAccount:"
  }
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
  default     = "iap-private-network"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must use lowercase letters, numbers, and hyphens. it must start with a letter and end with a letter or number."

  }

}

variable "subnets" {
  description = "Map of subnets to create inside the VPC."
  type = map(object({
    cidr_range = string
    region     = optional(string)
  }))

  # enforce naming conventions
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
    error_message = "Each cidr range must be a valid cidr block."
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


variable "vm_service_account_id" {
  description = "Account ID for the vm service account"
  type        = string
  default     = "iap-private-vm-sa"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.vm_service_account_id))
    error_message = "Service account ID must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."

  }
}

variable "vm_service_account_display_name" {
  description = "Display name for the VM service account"
  type        = string
  default     = "IAP Private VM service account"
}

variable "vm_name" {
  description = "The name of the compute engine vm."
  type        = string
  default     = "iap-private-vm"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.vm_name))
    error_message = "VM name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."

  }
}

variable "vm_machine_type" {
  description = "The machine type for the Compute Engine VM."
  type        = string
  default     = "e2-micro"
}

variable "vm_zone" {
  description = "The zone where the Compute Engine VM will be created."
  type        = string
  default     = "asia-southeast2-a"
}

variable "vm_subnet_key" {
  description = "The key of the subnet from the network module where the VM should be attached."
  type        = string
  default     = "app"

  validation {
    condition     = contains(["app", "db"], var.vm_subnet_key)
    error_message = "vm_subnet_key must be either app or db."
  }
}

variable "vm_tags" {
  description = "Network tags attached to the VM."
  type        = list(string)
  default     = ["iap-ssh"]
}

variable "enable_oslogin" {
  description = "Whether to enable OS Login on the VM."
  type        = bool
  default     = true
}