output "environment" {
  description = "The environment used for this lab."
  value       = var.environment
}

output "vcp_network_name" {

  description = "The final vcp network name."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {

  description = "the id of the vpc"
  value       = google_compute_network.vpc_network.id
}

output "subnetwork_name" {
  description = "the final subnetwork name"
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "the subnet cidr range"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "lab_summary" {
  value = {
    project     = var.project
    environment = var.environment
    region      = var.region
    network     = google_compute_network.vpc_network.name
    subnet      = google_compute_subnetwork.subnet.name
    cidr        = google_compute_subnetwork.subnet.ip_cidr_range
  }
}