output "network_name" {
  description = "The VPC network name."
  value       = google_compute_network.vpc_network.name
}

output "network_id" {
  description = "The VPC network ID."
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The subnet name."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "The subnet CIDR range."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "lab_summary" {
  description = "Summary of Lab 009."

  value = {
    project     = var.project
    environment = var.environment
    region      = var.region
    network     = google_compute_network.vpc_network.name
    subnet      = google_compute_subnetwork.subnet.name
    cidr        = google_compute_subnetwork.subnet.ip_cidr_range
  }
}