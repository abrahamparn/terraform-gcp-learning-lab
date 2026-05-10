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

module "vm_service_account" {
  source = "./modules/gcp-service-account"

  account_id   = "${var.environment}-${var.vm_service_account_id}"
  display_name = "${var.environment} ${var.vm_service_account_display_name}"
}

resource "google_project_iam_member" "iap_tunnel_user" {
  project = var.project
  role    = "roles/iap.tunnelResourceAccessor"
  member  = var.admin_principal
}

resource "google_project_iam_member" "os_admin_login" {
  project = var.project
  role    = "roles/compute.osAdminLogin"
  member  = var.admin_principal

}

resource "google_service_account_iam_member" "vm_service_account_user" {
  service_account_id = module.vm_service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = var.admin_principal
}

module "vm" {
  source = "./modules/gcp-vm"

  environment           = var.environment
  vm_name               = var.vm_name
  machine_type          = var.vm_machine_type
  zone                  = var.vm_zone
  tags                  = var.vm_tags
  subnetwork_self_link  = module.network.subnets[var.vm_subnet_key].self_link
  service_account_email = module.vm_service_account.email
  startup_script_path   = "${path.module}/startup.sh"
  enable_oslogin        = var.enable_oslogin

  depends_on = [
    google_project_iam_member.iap_tunnel_user,
    google_project_iam_member.os_admin_login,
    google_service_account_iam_member.vm_service_account_user
  ]
}