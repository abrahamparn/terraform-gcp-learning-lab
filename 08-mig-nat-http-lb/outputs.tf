output "network_name" {
  description = "The VPC network name."
  value       = module.network.network_name
}

output "subnets" {
  description = "Subnets created by the network module."
  value       = module.network.subnets
}

output "firewall_rules" {
  description = "Firewall rules created by the network module."
  value       = module.network.firewall_rules
}

output "cloud_nat_name" {
  description = "Cloud NAT gateway name."
  value       = module.cloud_nat.nat_name
}

output "cloud_router_name" {
  description = "Cloud Router name."
  value       = module.cloud_nat.router_name
}

output "health_check_name" {
  description = "HTTP health check name."
  value       = google_compute_health_check.http.name
}

output "mig_name" {
  description = "Managed instance group name."
  value       = module.mig.mig_name
}

output "mig_instance_group" {
  description = "Managed instance group backend URL."
  value       = module.mig.mig_instance_group
}

output "load_balancer_ip" {
  description = "External HTTP load balancer IP."
  value       = module.http_lb.load_balancer_ip
}

output "load_balancer_url" {
  description = "External HTTP load balancer URL."
  value       = module.http_lb.load_balancer_url
}

output "curl_test_command" {
  description = "Command to test the load balancer."
  value       = "curl -i ${module.http_lb.load_balancer_url}"
}

output "lab_summary" {
  description = "Summary of Lab 008."

  value = {
    project           = var.project
    environment       = var.environment
    region            = var.region
    network_name      = module.network.network_name
    mig_name          = module.mig.mig_name
    mig_size          = var.mig_instance_count
    app_port          = var.app_port
    cloud_nat         = module.cloud_nat.nat_name
    health_check      = google_compute_health_check.http.name
    load_balancer_ip  = module.http_lb.load_balancer_ip
    load_balancer_url = module.http_lb.load_balancer_url
  }
}