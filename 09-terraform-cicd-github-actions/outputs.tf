output "network_name" {
  description = "The VPC network name."
  value       = google_compute_network.vpc_network.name
}

output "network_id" {
  description = "The VPC network ID."
  value       = google_compute_network.vpc_network.id
}

output "subnets" {
  description = "Subnets created by this lab."

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

output "lab_summary" {
  description = "Summary of Lab 009."

  value = {
    project      = var.project
    environment  = var.environment
    region       = var.region
    network      = google_compute_network.vpc_network.name
    subnet_count = length(google_compute_subnetwork.subnets)
    subnets = {
      for subnet_key, subnet in google_compute_subnetwork.subnets :
      subnet_key => subnet.ip_cidr_range
    }
  }
}
