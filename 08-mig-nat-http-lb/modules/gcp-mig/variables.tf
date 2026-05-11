variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "mig_name" {
  description = "The base name for the MIG"
  type        = string
}

variable "region" {
  description = "Region for the regional MIG."
  type        = string
}

variable "zone" {
  description = "Zone used in the regional MIG distribution policy."
  type        = string
}

variable "machine_type" {
  description = "Machine type for instances."
  type        = string
}


variable "subnetwork_self_link" {
  description = "Self-link of the subnet where the network will be attached to tne vm"
  type        = string
}

variable "tags" {
  description = "Network tags attached to the instance"
  type        = list(string)
}

variable "startup_script_path" {
  description = "Path to the startup script."
  type        = string

}

variable "target_size" {
  description = "Number of instances in the MIG."
  type        = number

}

variable "app_port" {
  description = "Application port served by backend instances"
  type        = number
}

variable "health_check_self_link" {
  description = "Self-link of the health check used for autohealing."
  type        = string
}