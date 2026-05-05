output "vpc_network_name" {
  description = "The name of the VPC network created by Terraform."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "The ID of the VPC network created by Terraform."
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The name of the subnet created by Terraform."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "The CIDR range of the subnet created by Terraform."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "vm_instance_name" {
  description = "The name of the VM instance created by Terraform."
  value       = google_compute_instance.vm_instance.name
}

output "vm_instance_zone" {
  description = "The zone where the VM instance was created."
  value       = google_compute_instance.vm_instance.zone
}

output "vm_internal_ip" {
  description = "The internal IP address of the VM instance."
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}

output "vm_self_link" {
  description = "The self-link of the VM instance."
  value       = google_compute_instance.vm_instance.self_link
}

output "lab_summary" {
  description = "A structured summary of the resources created in this lab."

  value = {
    project        = var.project
    region         = var.region
    zone           = var.zone
    vpc_name       = google_compute_network.vpc_network.name
    subnet_name    = google_compute_subnetwork.subnet.name
    subnet_cidr    = google_compute_subnetwork.subnet.ip_cidr_range
    vm_name        = google_compute_instance.vm_instance.name
    vm_internal_ip = google_compute_instance.vm_instance.network_interface[0].network_ip
  }
}