locals {
  final_network_name = "${var.environment}-${var.network_name}"
}

resource "google_compute_network" "vpc_network" {
  name                    = local.final_network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name = "${var.environment}-${each.key}-subnets"

  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = each.value.cidr_range

}


resource "google_compute_firewall" "ingress_rules" {
  for_each      = var.firewall_rules
  name          = "${var.environment}-${each.key}"
  network       = google_compute_network.vpc_network.name
  description   = each.value.description
  direction     = "INGRESS"
  source_ranges = each.value.source_ranges
  target_tags   = each.value.target_tags

  dynamic "allow" {
    for_each = each.value.allow
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }
}