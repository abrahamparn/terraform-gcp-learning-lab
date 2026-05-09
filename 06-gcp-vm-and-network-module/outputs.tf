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

output "vm_name" {
  description = "The name of the VM created in the selected subnet."
  value       = module.vm.vm_name
}

output "vm_id" {
  description = "The ID of the VM."
  value       = module.vm.vm_id
}

output "vm_zone" {
  description = "The zone of the VM."
  value       = module.vm.vm_zone
}

output "vm_machine_type" {
  description = "The machine type of the VM."
  value       = module.vm.vm_machine_type
}

output "vm_internal_ip" {
  description = "The internal IP address of the VM."
  value       = module.vm.vm_internal_ip
}

output "vm_selected_subnet_key" {
  description = "The subnet key selected from the network module output."
  value       = var.vm_subnet_key
}

output "vm_selected_subnet_self_link" {
  description = "The subnet self-link consumed from the network module output."
  value       = module.network.subnets[var.vm_subnet_key].self_link
}

output "lab_summary" {
  description = "Summary of this VM and network module output lab."

  value = {
    project        = var.project
    environment    = var.environment
    region         = var.region
    network_name   = module.network.network_name
    subnet_count   = length(module.network.subnets)
    firewall_count = length(module.network.firewall_rules)
    vm_name        = module.vm.vm_name
    vm_zone        = module.vm.vm_zone
    vm_internal_ip = module.vm.vm_internal_ip
    vm_subnet_key  = var.vm_subnet_key
    vm_subnet_link = module.network.subnets[var.vm_subnet_key].self_link
    vm_external_ip = "none"
  }
}
