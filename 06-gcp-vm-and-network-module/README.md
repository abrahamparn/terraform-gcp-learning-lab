# Lab 06 - GCP VM and Network Module Composition

This lab extends the previous Terraform module lab by adding a reusable Compute Engine VM module.

In the previous lab, I created a reusable `gcp-network` module that provisions:

- a custom VPC network
- multiple subnets
- firewall rules
- network outputs

In this lab, I added a second module called `gcp-vm`.

The main learning goal is to understand how one module can produce outputs that are then consumed by another module.

## What This Lab Creates

This lab provisions the following Google Cloud resources:

| Resource               | Module        | Description                                 |
| ---------------------- | ------------- | ------------------------------------------- |
| Custom VPC network     | `gcp-network` | Main VPC network                            |
| App subnet             | `gcp-network` | Subnet for application workloads            |
| DB subnet              | `gcp-network` | Subnet for database workloads               |
| IAP SSH firewall rule  | `gcp-network` | Allows SSH through Identity-Aware Proxy     |
| Internal firewall rule | `gcp-network` | Allows internal traffic between lab subnets |
| Compute Engine VM      | `gcp-vm`      | Private VM attached to the app subnet       |

## Main Concept

The important concept in this lab is module composition.

```text
gcp-network module creates the network.
gcp-network module exposes subnet outputs.
root module passes the selected subnet output into the gcp-vm module.
gcp-vm module creates a VM inside that subnet.
```

The VM does not directly create its own network.

Instead, it consumes the subnet information created by the network module.

## Folder Structure

```text
06-gcp-vm-and-network-module/
├── backend.tf
├── main.tf
├── modules
│   ├── gcp-network
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── gcp-vm
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── README.md
├── startup.sh
├── terraform.tfvars
├── terraform.tfvars.example
└── variables.tf
```

## Architecture

```text
Root Module
│
├── module.network
│   ├── VPC network
│   ├── app subnet
│   ├── db subnet
│   ├── IAP SSH firewall rule
│   └── internal firewall rule
│
└── module.vm
    └── Compute Engine VM attached to module.network.subnets["app"]
```

## Remote State

This lab uses Google Cloud Storage as the Terraform backend.

Example `backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/06-gcp-vm-and-network-module"
  }
}
```

The expected remote state path is:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/06-gcp-vm-and-network-module/default.tfstate
```

## Root Module

The root module is responsible for:

- configuring the Google provider
- configuring the remote backend
- calling the `gcp-network` module
- calling the `gcp-vm` module
- passing network module outputs into the VM module
- exposing final outputs

The important flow is:

```hcl
subnetwork_self_link = module.network.subnets[var.vm_subnet_key].self_link
```

This means:

```text
Take the selected subnet output from the network module and pass it into the VM module.
```

## Network Module

The `gcp-network` module creates:

- one custom VPC network
- multiple subnets using `for_each`
- firewall rules using `for_each`
- dynamic firewall `allow` blocks

The module exposes outputs such as:

- network name
- network ID
- subnet details
- firewall rule details

## VM Module

The `gcp-vm` module creates:

- one Compute Engine VM
- Debian 12 boot disk
- `e2-micro` machine type
- internal IP only
- network tags
- startup script

The VM is attached to the subnet passed from the network module.

The VM does not have an external IP address.

## Startup Script

The VM uses `startup.sh` to install Nginx.

```bash
#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html <<EOF
<!doctype html>
<html>
  <head>
    <title>Terraform Module Output VM</title>
  </head>
  <body>
    <h1>Hello from Terraform</h1>
    <p>This VM was created using a subnet output from the network module.</p>
  </body>
</html>
EOF

systemctl enable nginx
systemctl restart nginx
```

## Variables

This lab uses `terraform.tfvars` for local values.

Example:

```hcl
project      = "terraform-gcp-learning-lab"
region       = "asia-southeast2"
environment  = "dev"
network_name = "network-module"

subnets = {
  app = {
    cidr_range = "10.50.1.0/24"
  }

  db = {
    cidr_range = "10.50.2.0/24"
  }
}

firewall_rules = {
  allow-iap-ssh = {
    description   = "Allow SSH through IAP only."
    source_ranges = ["35.235.240.0/20"]
    target_tags   = ["iap-ssh"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["22"]
      }
    ]
  }

  allow-internal = {
    description   = "Allow internal traffic between lab subnets."
    source_ranges = ["10.50.0.0/16"]

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

vm_name         = "module-output-vm"
vm_machine_type = "e2-micro"
vm_zone         = "asia-southeast2-a"
vm_subnet_key   = "app"
vm_tags         = ["iap-ssh"]
```

## Git Safety

Do not commit:

```text
terraform.tfvars
.terraform/
terraform.tfstate
terraform.tfstate.backup
```

Commit:

```text
terraform.tfvars.example
.terraform.lock.hcl
```

## Initialize

```bash
terraform init
```

Expected module initialization:

```text
Initializing modules...
- network in modules/gcp-network
- vm in modules/gcp-vm
```

## Format

Because this lab contains nested module folders, use:

```bash
terraform fmt -recursive
```

## Validate

```bash
terraform validate
```

Expected output:

```text
Success! The configuration is valid.
```

## Plan

```bash
terraform plan
```

Expected result:

```text
Plan: 6 to add, 0 to change, 0 to destroy.
```

Expected resources:

```text
module.network.google_compute_network.vpc_network
module.network.google_compute_subnetwork.subnets["app"]
module.network.google_compute_subnetwork.subnets["db"]
module.network.google_compute_firewall.ingress_rules["allow-iap-ssh"]
module.network.google_compute_firewall.ingress_rules["allow-internal"]
module.vm.google_compute_instance.app_vm
```

## Apply

```bash
terraform apply
```

Type:

```text
yes
```

Expected result:

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

## Outputs

After apply, run:

```bash
terraform output
```

Important outputs:

```text
network_name = "dev-network-module"
vm_name = "dev-module-output-vm"
vm_internal_ip = "10.50.1.2"
vm_selected_subnet_key = "app"
vm_selected_subnet_self_link = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
```

The `lab_summary` output shows the overall result:

```text
lab_summary = {
  "environment" = "dev"
  "firewall_count" = 2
  "network_name" = "dev-network-module"
  "project" = "terraform-gcp-learning-lab"
  "region" = "asia-southeast2"
  "subnet_count" = 2
  "vm_external_ip" = "none"
  "vm_internal_ip" = "10.50.1.2"
  "vm_name" = "dev-module-output-vm"
  "vm_subnet_key" = "app"
  "vm_zone" = "asia-southeast2-a"
}
```

## Verify VM

```bash
gcloud compute instances list --filter="name=dev-module-output-vm"
```

## Verify Network

```bash
gcloud compute networks list --filter="name=dev-network-module"
```

## Verify Subnets

```bash
gcloud compute networks subnets list \
  --filter="network:dev-network-module"
```

## Verify Remote State

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/06-gcp-vm-and-network-module/
```

Expected output:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/06-gcp-vm-and-network-module/default.tfstate
```

## Destroy

Because this is a learning lab, destroy the resources after testing.

```bash
terraform destroy
```

Type:

```text
yes
```

Expected result:

```text
Destroy complete! Resources: 6 destroyed.
```

## What I Learned

This lab demonstrates module composition.

The `gcp-network` module creates networking resources.

The `gcp-vm` module creates compute resources.

The root module connects them together by passing the selected subnet output from the network module into the VM module.

The most important pattern is:

```text
module output -> root module -> another module input
```

This is closer to how larger Terraform projects are structured.
