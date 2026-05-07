output "vpc_network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "The ID of the VPC network."
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The name of the subnet."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "The CIDR range of the subnet."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "remote_state_note" {
  description = "Reminder that this lab uses a GCS backend for Terraform state."
  value       = "Terraform state for this lab is stored in Google Cloud Storage, not only in a local terraform.tfstate file."
}