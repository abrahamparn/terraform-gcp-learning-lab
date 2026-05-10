variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "vm_name" {
  description = "Base VM name."
  type        = string
}

variable "machine_type" {
  description = "Machine type for the VM."
  type        = string
}

variable "zone" {
  description = "Zone where the VM will be created."
  type        = string
}

variable "tags" {
  description = "Network tags for the VM."
  type        = list(string)
}

variable "subnetwork_self_link" {
  description = "Self-link of the subnet where the VM will be attached."
  type        = string
}

variable "service_account_email" {
  description = "Service account email attached to the VM."
  type        = string
}

variable "startup_script_path" {
  description = "Path to the startup script file."
  type        = string
}

variable "enable_oslogin" {
  description = "Whether to enable OS Login on this VM."
  type        = bool
  default     = true
}