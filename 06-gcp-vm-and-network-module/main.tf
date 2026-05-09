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


module "vm" {
  source = "./modules/gcp-vm"

  environment = var.environment
  vm_name     = var.vm_name

  vm_machine_type = var.vm_machine_type
  vm_zone         = var.vm_zone
  vm_tags         = var.vm_tags


  subnet_self_link = module.network.subnets[var.vm_subnet_key].self_link
  startup_script   = file("${path.module}/startup.sh")
}
