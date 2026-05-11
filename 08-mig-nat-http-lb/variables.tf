variable "project" {
  description = "The google Cloud project Id where resources will be created."
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "The project variable must not be empty"
  }
}

variable "region" {
  description = "Default Googl Cloud region for regional resources"
  type        = string
  default     = "asia-southeast2"

  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "Region must be one of: asia-southeast2, asia-southeast1, or us-central1."
  }
}

variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

variable "network_name" {
  description = "Base name of the VPC network"
  type        = string
  default     = "mig-lb-network"

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
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key))
    ])
    error_message = "Each subnet key must be a valid lowercase name"
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(cidrhost(subnet.cidr_range, 0))
    ])
    error_message = "Each cidr_range must be a valid, mathematically sound IPv4 CIDR block (e.g., '10.0.0.0/24')."
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
      prots    = optional(list(string))
    }))
  }))

  default = {}
}

variable "mig_name" {
  description = "Base name for the managed instance group."
  type        = string
  default     = "web-mig"
}

variable "mig_instance_count" {
  description = "Number of instances in the managed instacne group."
  type        = number
  default     = 2

  validation {
    condition     = var.mig_instance_count >= 1 && var.mig_instance_count <= 3
    error_message = "For this learning lab, mig_instance_count must be between 1 and 3."
  }

}

variable "mig_machine_type" {
  description = "Machine type for MIG instances."
  type        = string
  default     = "e2-micro"
}

variable "mig_zone" {
  description = "Zone used by the regional MIG distribution policy."
  type        = string
  default     = "asia-southeast2-a"
}

variable "mig_subnet_key" {
  description = "Subnet key from the network module where MIG instances will be attached."
  type        = string
  default     = "app"

  validation {
    condition     = contains(["app", "db"], var.mig_subnet_key)
    error_message = "mig_subnet_key must be either app or db."


  }
}

variable "mig_tags" {
  description = "Netork tags attached to MIG instances."
  type        = list(string)
  default     = ["web-backend"]
}

variable "lb_name" {
  description = "Base name for the HTTP load balancer"
  type        = string
  default     = "web-lb"
}

variable "app_port" {
  description = "Application port exposed by backend instances"
  type        = number
  default     = 80
}