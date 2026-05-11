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

module "network" {
  source = "./modules/gcp-network"

  environment    = var.environment
  region         = var.region
  network_name   = var.network_name
  subnets        = var.subnets
  firewall_rules = var.firewall_rules
}

module "cloud_nat" {
  source = "./modules/gcp-cloud-nat"

  environment       = var.environment
  region            = var.region
  network_self_link = module.network.network_self_link
}
resource "google_compute_health_check" "http" {
  name = "${var.environment}-${var.lb_name}-http-health-check"

  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = var.app_port
    request_path = "/"
  }
}

module "mig" {
  source = "./modules/gcp-mig"

  environment          = var.environment
  mig_name             = var.mig_name
  region               = var.region
  zone                 = var.mig_zone
  machine_type         = var.mig_machine_type
  subnetwork_self_link = module.network.subnets[var.mig_subnet_key].self_link
  tags                 = var.mig_tags

  startup_script_path    = "${path.module}/startup.sh"
  target_size            = var.mig_instance_count
  app_port               = var.app_port
  health_check_self_link = google_compute_health_check.http.self_link

  depends_on = [module.cloud_nat]
}

module "http_lb" {
  source = "./modules/gcp-http-lb"

  environment            = var.environment
  lb_name                = var.lb_name
  backend_instance_group = module.mig.mig_instance_group
  health_check_self_link = google_compute_health_check.http.self_link
  app_port               = var.app_port

}