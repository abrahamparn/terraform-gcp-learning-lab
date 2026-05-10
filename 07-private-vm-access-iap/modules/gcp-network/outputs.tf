output "network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.vpc_network.name
}

output "network_id" {
  description = "The ID of the VPC network."
  value       = google_compute_network.vpc_network.id
}

output "network_self_link" {
  description = "The self-link of the VPC network."
  value       = google_compute_network.vpc_network.self_link
}

output "subnets" {
  description = "Subnets created by this module."
  value = {
    for subnet_key, subnet in google_compute_subnetwork.subnets :
    subnet_key => {
      name       = subnet.name
      id         = subnet.id
      region     = subnet.region
      cidr_range = subnet.ip_cidr_range
      self_link  = subnet.self_link
    }
  }
}

output "firewall_rules" {
  description = "Firewall rules created by this module."

  value = {
    for rule_key, rule in google_compute_firewall.ingress_rules :
    rule_key => {
      name          = rule.name
      id            = rule.id
      source_ranges = rule.source_ranges
      target_tags   = rule.target_tags
    }
  }
}