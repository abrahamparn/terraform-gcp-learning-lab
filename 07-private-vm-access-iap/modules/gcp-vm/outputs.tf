output "vm_name" {
  description = "The VM name."
  value       = google_compute_instance.app_vm.name
}

output "vm_id" {
  description = "The VM ID."
  value       = google_compute_instance.app_vm.id
}

output "vm_zone" {
  description = "The VM zone."
  value       = google_compute_instance.app_vm.zone
}

output "vm_machine_type" {
  description = "The VM machine type."
  value       = google_compute_instance.app_vm.machine_type
}

output "vm_internal_ip" {
  description = "The internal IP address of the VM."
  value       = google_compute_instance.app_vm.network_interface[0].network_ip
}

output "vm_self_link" {
  description = "The VM self-link."
  value       = google_compute_instance.app_vm.self_link
}

output "vm_service_account_email" {
  description = "The service account email attached to the VM."
  value       = google_compute_instance.app_vm.service_account[0].email
}

