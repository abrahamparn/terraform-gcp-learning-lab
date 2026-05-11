output "instance_template_self_link" {
  description = "The instance template self-link."
  value       = google_compute_instance_template.template.self_link
}

output "mig_name" {
  description = "The managed instance group name."
  value       = google_compute_region_instance_group_manager.mig.name
}

output "mig_instance_group" {
  description = "The instance group URL used by the backend service."
  value       = google_compute_region_instance_group_manager.mig.instance_group
}

output "mig_region" {
  description = "The MIG region."
  value       = google_compute_region_instance_group_manager.mig.region
}