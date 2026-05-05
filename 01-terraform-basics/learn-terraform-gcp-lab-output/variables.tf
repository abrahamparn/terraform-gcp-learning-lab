variable "project" {
  description = "The google cloud project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "The region of GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The google cloud zone for the vm"
  type        = string
  default     = "us-central1-c"
}

variable "network_name" {
  description = "the name of the vpc network"
  type        = string
  default     = "terraform-output-network"
}
variable "subnet_name" {
  description = "the name of the subnet"
  type        = string
  default     = "terraform-output-subnet"
}

variable "subnet_cidr_range" {
  description = "the cidr range for the subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "instance_name" {
  description = "the name of the compute engine vm instance"
  type        = string
  default     = "terraform-output-vm"
}

variable "machine_type" {
  description = "the machine type for the compute engine vm instance"
  type        = string
  default     = "e2-micro"
}