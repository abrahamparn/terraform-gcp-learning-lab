terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.environment}-${var.network_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "${var.environment}-${each.key}-subnet"
  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = each.value.cidr_range
}
