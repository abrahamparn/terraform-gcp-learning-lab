output "load_balancer_ip" {
  description = "The external IP address of the HTTP load balancer."
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_url" {
  description = "The HTTP URL of the load balancer."
  value       = "http://${google_compute_global_address.lb_ip.address}"
}

output "backend_service_name" {
  description = "The backend service name."
  value       = google_compute_backend_service.backend.name
}

output "forwarding_rule_name" {
  description = "The forwarding rule name."
  value       = google_compute_global_forwarding_rule.http_forwarding_rule.name
}