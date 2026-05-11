output "router_name" {
  description = "The Cloud Router name."
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "The Cloud NAT gateway name."
  value       = google_compute_router_nat.nat.name
}

output "nat_region" {
  description = "The region of the Cloud NAT gateway."
  value       = google_compute_router_nat.nat.region
}