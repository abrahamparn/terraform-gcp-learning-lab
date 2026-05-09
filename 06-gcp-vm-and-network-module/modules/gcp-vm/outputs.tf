output "vm_name" {
  description = "The name of the VM."
  value       = google_compute_instance.app_vm.name
}

output "vm_id" {
  description = "The ID of the VM."
  value       = google_compute_instance.app_vm.id
}

output "vm_self_link" {
  description = "The self-link of the VM."
  value       = google_compute_instance.app_vm.self_link
}

output "vm_zone" {
  description = "The zone of the VM."
  value       = google_compute_instance.app_vm.zone
}

output "vm_machine_type" {
  description = "The machine type of the VM."
  value       = google_compute_instance.app_vm.machine_type
}

output "vm_internal_ip" {
  description = "The internal IP address of the VM."
  value       = google_compute_instance.app_vm.network_interface[0].network_ip
}

output "vm_tags" {
  description = "The network tags attached to the VM."
  value       = google_compute_instance.app_vm.tags
}
