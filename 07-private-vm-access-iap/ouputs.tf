output "network_name" {
  description = "The VPC network name created by the network module."
  value       = module.network.network_name
}

output "network_id" {
  description = "The VPC network ID created by the network module."
  value       = module.network.network_id
}

output "subnets" {
  description = "Subnets created by the network module."
  value       = module.network.subnets
}

output "firewall_rules" {
  description = "Firewall rules created by the network module."
  value       = module.network.firewall_rules
}

output "vm_service_account_email" {
  description = "The service account email attached to the VM."
  value       = module.vm_service_account.email
}

output "vm_name" {
  description = "The VM name."
  value       = module.vm.vm_name
}

output "vm_id" {
  description = "The VM ID."
  value       = module.vm.vm_id
}

output "vm_zone" {
  description = "The VM zone."
  value       = module.vm.vm_zone
}

output "vm_internal_ip" {
  description = "The VM internal IP."
  value       = module.vm.vm_internal_ip
}

output "vm_machine_type" {
  description = "The VM machine type."
  value       = module.vm.vm_machine_type
}

output "vm_selected_subnet_key" {
  description = "The subnet key selected from the network module output."
  value       = var.vm_subnet_key
}

output "vm_selected_subnet_self_link" {
  description = "The subnet self-link consumed from the network module output."
  value       = module.network.subnets[var.vm_subnet_key].self_link
}

output "iam_ssh_command" {
  description = "Command to SSH into the private VM through IAP."
  value       = "gcloud compute ssh ${module.vm.vm_name} --zone=${module.vm.vm_zone} --tunnel-through-iap"

}

output "startup_script_verification_command" {
  description = "Command to verify Nginx from inside the VM after SSH."
  value       = "curl -I http://localhost"
}

output "member" {
  description = "The IAM member string for the VM service account."
  value       = module.vm_service_account.member
}

output "lab_summary" {
  description = "Summary of the private VM access lab."

  value = {
    project                  = var.project
    environment              = var.environment
    region                   = var.region
    network_name             = module.network.network_name
    subnet_count             = length(module.network.subnets)
    firewall_count           = length(module.network.firewall_rules)
    vm_name                  = module.vm.vm_name
    vm_zone                  = module.vm.vm_zone
    vm_internal_ip           = module.vm.vm_internal_ip
    vm_external_ip           = "none"
    vm_subnet_key            = var.vm_subnet_key
    vm_subnet_link           = module.network.subnets[var.vm_subnet_key].self_link
    vm_service_account_email = module.vm_service_account.email
    os_login_enabled         = var.enable_oslogin
    iap_ssh_enabled_pattern  = true
  }
}