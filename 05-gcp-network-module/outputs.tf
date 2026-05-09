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

output "lab_summary" {
  description = "Summary of this module-based network lab."

  value = {
    project        = var.project
    environment    = var.environment
    region         = var.region
    network_name   = module.network.network_name
    subnet_count   = length(module.network.subnets)
    firewall_count = length(module.network.firewall_rules)
  }
}