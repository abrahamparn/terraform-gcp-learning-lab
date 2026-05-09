
variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}


variable "vm_name" {
  description = "The name of the compute engine vm"
  type        = string

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.vm_name))
    error_message = "VM name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number"
  }
}

variable "vm_machine_type" {
  description = "The machine type for the compute engine vm"
  type        = string
}

variable "vm_zone" {
  description = "The zone where the compute engine VM will be created"
  type        = string
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
}

variable "startup_script" {
  description = "The startup script for my vm"
}

variable "subnet_self_link" {
  description = "the self link for my vm"
}