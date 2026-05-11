# 08 MIG NAT HTTP LB - Code Snapshot

This file contains the current Terraform code for `08-mig-nat-http-lb`.

Validation status at snapshot time:

```text
terraform validate
Success! The configuration is valid.
```

## Folder Structure

```text
08-mig-nat-http-lb/
├── backend.tf
├── main.tf
├── outputs.tf
├── startup.sh
├── terraform.tfvars
├── variables.tf
├── modules/
│   ├── gcp-cloud-nat/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-http-lb/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-mig/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-network/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── gcp-service-account/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
```

## backend.tf

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/08-mig-http-load-balancer"
  }
}
```

## main.tf

```hcl
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
  source                = "./modules/gcp-mig"
  service_account_email = module.service_account.email

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

module "service_account" {
  source = "./modules/gcp-service-account"

  account_id   = "${var.environment}-${var.mig_service_account_id}"
  display_name = "${var.environment}-${var.mig_service_account_display_name}"
}

resource "google_project_iam_member" "iap_tunnel_user" {
  project = var.project
  role    = var.tunnel_role
  member  = var.admin_principal
}

resource "google_project_iam_member" "os_admin_login" {
  project = var.project
  role    = var.os_admin_login_role
  member  = var.admin_principal
}

resource "google_service_account_iam_member" "vm_service_account_user" {
  role               = var.service_account_user_role
  member             = var.admin_principal
  service_account_id = module.service_account.name
}
```

## variables.tf

```hcl
variable "project" {
  description = "The google Cloud project Id where resources will be created."
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "The project variable must not be empty"
  }
}

variable "region" {
  description = "Default Googl Cloud region for regional resources"
  type        = string
  default     = "asia-southeast2"

  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "Region must be one of: asia-southeast2, asia-southeast1, or us-central1."
  }
}

variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

variable "network_name" {
  description = "Base name of the VPC network"
  type        = string
  default     = "mig-lb-network"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."


  }
}

variable "subnets" {
  description = "Map of subnets to create inside the VPC."

  type = map(object({
    cidr_range = string
    region     = optional(string)
  }))

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key))
    ])
    error_message = "Each subnet key must be a valid lowercase name"
  }

  validation {
    condition = alltrue([
      for subnet_key, subnet in var.subnets :
      can(cidrhost(subnet.cidr_range, 0))
    ])
    error_message = "Each cidr_range must be a valid, mathematically sound IPv4 CIDR block (e.g., '10.0.0.0/24')."
  }
}


variable "firewall_rules" {
  description = "Map of ingress firewall rules to create."
  type = map(object({
    description   = optional(string)
    source_ranges = list(string)
    target_tags   = optional(list(string), [])
    allow = list(object({
      protocol = string
      prots    = optional(list(string))
    }))
  }))

  default = {}
}

variable "mig_name" {
  description = "Base name for the managed instance group."
  type        = string
  default     = "web-mig"
}

variable "mig_instance_count" {
  description = "Number of instances in the managed instacne group."
  type        = number
  default     = 2

  validation {
    condition     = var.mig_instance_count >= 1 && var.mig_instance_count <= 3
    error_message = "For this learning lab, mig_instance_count must be between 1 and 3."
  }

}

variable "mig_machine_type" {
  description = "Machine type for MIG instances."
  type        = string
  default     = "e2-micro"
}

variable "mig_zone" {
  description = "Zone used by the regional MIG distribution policy."
  type        = string
  default     = "asia-southeast2-a"
}

variable "mig_subnet_key" {
  description = "Subnet key from the network module where MIG instances will be attached."
  type        = string
  default     = "app"

  validation {
    condition     = contains(["app", "db"], var.mig_subnet_key)
    error_message = "mig_subnet_key must be either app or db."


  }
}

variable "mig_tags" {
  description = "Netork tags attached to MIG instances."
  type        = list(string)
  default     = ["web-backend"]
}

variable "lb_name" {
  description = "Base name for the HTTP load balancer"
  type        = string
  default     = "web-lb"
}

variable "app_port" {
  description = "Application port exposed by backend instances"
  type        = number
  default     = 80
}

variable "tunnel_role" {
  description = "IAP Tunnel Role"
  type        = string
  default     = "roles/iap.tunnelResourceAccessor"
}

variable "os_admin_login_role" {
  description = "The necessary iap for os admin login"
  type        = string
  default     = "roles/compute.osAdminLogin"
}

variable "service_account_user_role" {
  description = "The service account of a user"
  type        = string
  default     = "roles/iam.serviceAccountUser"
}

variable "admin_principal" {
  description = "IAM Principal allowed to access the private VM through IAP and OS Login Example: user:name@example.com"
  type        = string
  validation {
    condition     = can(regex("^(user|group|serviceAccount):.+", var.admin_principal))
    error_message = "admin_principal must start with user:, group;, or serviceAccount:"
  }
}

variable "mig_service_account_id" {
  description = "Account ID for the vm service account"
  type        = string
  default     = "iap-private-vm-sa"
  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.mig_service_account_id))
    error_message = "Service account ID must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number"
  }
}


variable "mig_service_account_display_name" {
  description = "Display name for the VM service account"
  type        = string
  default     = "IAP Private VM service account"
}
```

## outputs.tf

```hcl
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
```

## terraform.tfvars

```hcl
project         = "terraform-gcp-learning-lab"
region          = "asia-southeast2"
environment     = "dev"
admin_principal = "user:abram.domu@gmail.com"


network_name = "mig-lb-network"

subnets = {
  app = {
    cidr_range = "10.80.1.0/24"
  }

  db = {
    cidr_range = "10.80.2.0/24"
  }
}

firewall_rules = {
  allow-lb-health-check = {
    description   = "Allow Google Cloud load balancer health checks and proxy traffic."
    source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
    target_tags   = ["web-backend"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["80"]
      }
    ]
  }

  allow-internal = {
    description   = "Allow internal traffic between lab subnets."
    source_ranges = ["10.80.0.0/16"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["0-65535"]
      },
      {
        protocol = "udp"
        ports    = ["0-65535"]
      },
      {
        protocol = "icmp"
      }
    ]
  }
}

mig_name           = "web-mig"
mig_instance_count = 2
mig_machine_type   = "e2-micro"
mig_zone           = "asia-southeast2-a"
mig_subnet_key     = "app"
mig_tags           = ["web-backend"]
mig_service_account_id           = "web-mig-sa"
mig_service_account_display_name = "Web MIG Service Account"

lb_name  = "web-lb"
app_port = 80
```

## startup.sh

```bash
#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

HOSTNAME="$(hostname)"
LOCAL_IP="$(hostname -I | awk '{print $1}')"

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head>
    <title>Terraform MIG Load Balancer Lab</title>
  </head>
  <body>
    <h1>Hello from Terraform Lab 008</h1>
    <p>This page is served from a private VM inside a Managed Instance Group.</p>
    <p>Hostname: ${HOSTNAME}</p>
    <p>Internal IP: ${LOCAL_IP}</p>
  </body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx
```

## modules/gcp-network/main.tf

```hcl
locals {
  final_network_name = "${var.environment}-${var.network_name}"
}

resource "google_compute_network" "vpc_network" {
  name                    = local.final_network_name
  auto_create_subnetworks = false
}


resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "${var.environment}-${each.key}-subnet"
  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = each.value.cidr_range
}

resource "google_compute_firewall" "ingress_rules" {
  for_each = var.firewall_rules

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
```

## modules/gcp-network/variables.tf

```hcl
variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
}

variable "region" {
  description = "Default google cloud region for regional resoruces."
  type        = string
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create inside the VPC"
  type = map(object({
    cidr_range = string
    region     = optional(string)

  }))

}

variable "firewall_rules" {
  description = "Map of ingress firewall rules to create."
  type = map(object({
    description   = optional(string)
    source_ranges = list(string)
    target_tags   = optional(list(string), [])
    allow = list(object({
      protocol = string
      ports    = optional(list(string))
    }))
  }))

  default = {}
}
```

## modules/gcp-network/outputs.tf

```hcl
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
```

## modules/gcp-cloud-nat/main.tf

```hcl
resource "google_compute_router" "router" {
  name    = "${var.environment}-${var.router_name}"
  region  = var.region
  network = var.network_self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.environment}-${var.nat_name}"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
```

## modules/gcp-cloud-nat/variables.tf

```hcl
variable "environment" {
  description = "Environment name used for resource naming"
  type        = string
}

variable "region" {
  description = "Region where Cloud Router and Cloud NAT will be created."
  type        = string
}


variable "network_self_link" {
  description = "Self-link of the VPC network."
  type        = string
}

variable "router_name" {
  description = "Base name of the router for the NAT"
  type        = string
  default     = "nat-router"
}

variable "nat_name" {
  description = "Base name for the cloud NAT Gateway"
  type        = string
  default     = "nat-gateway"
}
```

## modules/gcp-cloud-nat/outputs.tf

```hcl
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
```

## modules/gcp-service-account/main.tf

```hcl
resource "google_service_account" "this" {
  account_id   = var.account_id
  display_name = var.display_name
}
```

## modules/gcp-service-account/variables.tf

```hcl
variable "account_id" {
  description = "The service account id."
  type        = string
}

variable "display_name" {
  description = "Display name for the service account."
  type        = string
}
```

## modules/gcp-service-account/outputs.tf

```hcl
output "email" {
  description = "The service account email."
  value       = google_service_account.this.email
}

output "name" {
  description = "the fully qualified service account name"
  value       = google_service_account.this.name
}

output "member" {
  description = "The iam member for this service account."
  value       = "serviceAccount:${google_service_account.this.email}"
}
```

## modules/gcp-mig/main.tf

```hcl
resource "google_compute_instance_template" "template" {
  name_prefix  = "${var.environment}-${var.mig_name}-template-"
  machine_type = var.machine_type
  tags         = var.tags

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-balanced"
  }

  network_interface {
    subnetwork = var.subnetwork_self_link
  }

  metadata_startup_script = file(var.startup_script_path)

  lifecycle {
    create_before_destroy = true
  }


  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "mig" {
  name               = "${var.environment}-${var.mig_name}"
  region             = var.region
  base_instance_name = "${var.environment}-${var.mig_name}"
  target_size        = var.target_size
  version {
    instance_template = google_compute_instance_template.template.self_link

  }

  named_port {
    name = "http"

    port = var.app_port
  }

  distribution_policy_zones = [var.zone]

  auto_healing_policies {
    health_check      = var.health_check_self_link
    initial_delay_sec = 120
  }



}
```

## modules/gcp-mig/variables.tf

```hcl
variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "mig_name" {
  description = "The base name for the MIG"
  type        = string
}

variable "region" {
  description = "Region for the regional MIG."
  type        = string
}

variable "zone" {
  description = "Zone used in the regional MIG distribution policy."
  type        = string
}

variable "machine_type" {
  description = "Machine type for instances."
  type        = string
}


variable "subnetwork_self_link" {
  description = "Self-link of the subnet where the network will be attached to tne vm"
  type        = string
}

variable "tags" {
  description = "Network tags attached to the instance"
  type        = list(string)
}

variable "startup_script_path" {
  description = "Path to the startup script."
  type        = string

}

variable "target_size" {
  description = "Number of instances in the MIG."
  type        = number

}

variable "app_port" {
  description = "Application port served by backend instances"
  type        = number
}

variable "health_check_self_link" {
  description = "Self-link of the health check used for autohealing."
  type        = string
}

variable "service_account_email" {
  description = "Service account email attached to MIG instances."
  type        = string
}
```

## modules/gcp-mig/outputs.tf

```hcl
output "instance_template_self_link" {
  description = "The instance template self-link."
  value       = google_compute_instance_template.template.self_link
}

output "mig_name" {
  description = "The managed instance group name."
  value       = google_compute_region_instance_group_manager.mig.name
}

output "mig_instance_group" {
  description = "The instance group URL used by the backend service."
  value       = google_compute_region_instance_group_manager.mig.instance_group
}

output "mig_region" {
  description = "The MIG region."
  value       = google_compute_region_instance_group_manager.mig.region
}
```

## modules/gcp-http-lb/main.tf

```hcl
resource "google_compute_global_address" "lb_ip" {
  name = "${var.environment}-${var.lb_name}-ip"
}

resource "google_compute_backend_service" "backend" {
  name                  = "${var.environment}-${var.lb_name}-backend"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30

  health_checks = [
    var.health_check_self_link
  ]

  backend {
    group           = var.backend_instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.environment}-${var.lb_name}-url-map"
  default_service = google_compute_backend_service.backend.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.environment}-${var.lb_name}-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "${var.environment}-${var.lb_name}-http-forwarding-rule"
  ip_address            = google_compute_global_address.lb_ip.address
  ip_protocol           = "TCP"
  port_range            = tostring(var.app_port)
  load_balancing_scheme = "EXTERNAL_MANAGED"
  target                = google_compute_target_http_proxy.http_proxy.self_link
}
```

## modules/gcp-http-lb/variables.tf

```hcl
variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "lb_name" {
  description = "Base name for the HTTP load balancer."
  type        = string
}

variable "backend_instance_group" {
  description = "Instance group URL used as backend."
  type        = string
}

variable "health_check_self_link" {
  description = "Health check self-link for the backend service."
  type        = string
}

variable "app_port" {
  description = "Application port served by the backend."
  type        = number
}
```

## modules/gcp-http-lb/outputs.tf

```hcl
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
```

