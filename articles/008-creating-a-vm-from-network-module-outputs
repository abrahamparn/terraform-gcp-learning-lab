# Creating a VM from Network Module Outputs

In the previous lab, I created a reusable Terraform module for Google Cloud networking.

That module created:

- a custom VPC network
- multiple subnets
- firewall rules
- outputs for network, subnet, and firewall information

That was already an improvement from writing every resource directly in the root configuration.

However, the network module was still isolated. It created network resources, but nothing else was consuming those outputs yet.

So in this lab, I wanted to take the next logical step:

> Create a Compute Engine VM that uses the subnet output from the network module.

At first, I considered creating the VM directly in the root module. But then I changed the format and added a second module:

```text
modules/gcp-vm
```

So now the lab has two child modules:

```text
modules/gcp-network
modules/gcp-vm
```

The purpose of this lab is to understand module composition.

The main idea is:

```text
The network module creates the network.
The network module exposes subnet outputs.
The root module passes the selected subnet output into the VM module.
The VM module creates a VM inside that subnet.
```

## What This Lab Builds

This lab creates:

- one custom VPC network
- two subnets
- two firewall rules
- one Compute Engine VM
- a startup script that installs Nginx
- remote state in Google Cloud Storage
- outputs from both the network module and VM module

The final result from Terraform was:

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

The six resources were:

1. VPC network
2. app subnet
3. db subnet
4. IAP SSH firewall rule
5. internal firewall rule
6. Compute Engine VM

## Folder Structure

The final folder structure is:

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

There are now two child modules:

| Module        | Responsibility                           |
| ------------- | ---------------------------------------- |
| `gcp-network` | Creates VPC, subnets, and firewall rules |
| `gcp-vm`      | Creates the Compute Engine VM            |

The root module is responsible for wiring them together.

## The Main Concept: Module Composition

In the previous lab, the network module created subnets and exposed them through outputs.

The output looked conceptually like this:

```hcl
output "subnets" {
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
```

Because of this output, the root module can access:

```hcl
module.network.subnets["app"].self_link
```

In this lab, that value is passed into the VM module.

The important pattern is:

```text
network module output -> root module -> VM module input
```

This was the main learning point.

## Remote State

This lab still uses Google Cloud Storage as the Terraform backend.

Example `backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/06-gcp-vm-and-network-module"
  }
}
```

The state path is:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/06-gcp-vm-and-network-module/default.tfstate
```

Each lab has a different backend prefix so that the state files do not collide.

## Root `main.tf`

The root `main.tf` configures the provider and calls both modules.

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

module "vm" {
  source = "./modules/gcp-vm"

  environment          = var.environment
  vm_name              = var.vm_name
  machine_type         = var.vm_machine_type
  zone                 = var.vm_zone
  tags                 = var.vm_tags
  subnetwork_self_link = module.network.subnets[var.vm_subnet_key].self_link
  startup_script_path  = "${path.module}/startup.sh"
}
```

The most important line is:

```hcl
subnetwork_self_link = module.network.subnets[var.vm_subnet_key].self_link
```

This line means:

```text
Get the selected subnet from the network module output and pass it into the VM module.
```

If:

```hcl
vm_subnet_key = "app"
```

then Terraform resolves:

```hcl
module.network.subnets["app"].self_link
```

That is the subnet used by the VM.

## Why This is Better Than Hardcoding the Subnet

Without module outputs, I could hardcode the subnet like this:

```hcl
subnetwork = "dev-app-subnet"
```

But that is weaker.

The VM module should not guess or hardcode the subnet.

Instead, the network module creates the subnet, exposes the subnet self-link, and the root module passes that value into the VM module.

This makes the dependency clear.

The VM depends on the subnet created by the network module.

## VM Module

The VM module is responsible for creating the Compute Engine instance.

Inside:

```text
modules/gcp-vm/main.tf
```

the VM resource is defined like this:

```hcl
resource "google_compute_instance" "app_vm" {
  name         = "${var.environment}-${var.vm_name}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = var.tags

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnetwork_self_link
  }

  metadata_startup_script = file(var.startup_script_path)
}
```

The VM does not receive an external IP address because there is no `access_config` block inside the `network_interface`.

That means the VM is private.

This is intentional.

For this lab, I wanted the VM to use an internal IP only.

## Startup Script

The VM uses a startup script to install Nginx.

File:

```text
startup.sh
```

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

The startup script is passed into the VM module using:

```hcl
startup_script_path = "${path.module}/startup.sh"
```

Then the VM module reads it using:

```hcl
metadata_startup_script = file(var.startup_script_path)
```

## Firewall Rules

The network module creates two firewall rules.

### IAP SSH Rule

```text
dev-allow-iap-ssh
```

This allows SSH from:

```text
35.235.240.0/20
```

with the target tag:

```text
iap-ssh
```

The VM also has the tag:

```text
iap-ssh
```

That means the IAP SSH firewall rule applies to this VM.

### Internal Rule

```text
dev-allow-internal
```

This allows internal traffic from:

```text
10.50.0.0/16
```

This is used for internal communication between the lab subnets.

## Variables

The local values are stored in `terraform.tfvars`.

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

The important VM value is:

```hcl
vm_subnet_key = "app"
```

This tells Terraform to place the VM in the app subnet.

## Initialize Terraform

After preparing the files, I ran:

```bash
terraform init
```

Because this lab uses two child modules, Terraform initializes both modules.

Expected output includes:

```text
Initializing modules...
- network in modules/gcp-network
- vm in modules/gcp-vm
```

## Format and Validate

Because this lab has nested module folders, I used:

```bash
terraform fmt -recursive
```

Then I validated the configuration:

```bash
terraform validate
```

Expected output:

```text
Success! The configuration is valid.
```

## Terraform Plan

Next, I ran:

```bash
terraform plan
```

Terraform planned to create six resources:

```text
Plan: 6 to add, 0 to change, 0 to destroy.
```

The planned resources included:

```text
module.network.google_compute_firewall.ingress_rules["allow-iap-ssh"]
module.network.google_compute_firewall.ingress_rules["allow-internal"]
module.network.google_compute_network.vpc_network
module.network.google_compute_subnetwork.subnets["app"]
module.network.google_compute_subnetwork.subnets["db"]
module.vm.google_compute_instance.app_vm
```

This plan output is important because it shows the module boundaries.

Network resources are created under:

```text
module.network
```

The VM is created under:

```text
module.vm
```

## Apply

After reviewing the plan, I applied the configuration:

```bash
terraform apply
```

Then I typed:

```text
yes
```

Terraform completed successfully:

```text
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

## Terraform Outputs

After apply, I checked:

```bash
terraform output
```

The output showed the network, subnet, firewall, and VM information.

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
  "vm_subnet_link" = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
  "vm_zone" = "asia-southeast2-a"
}
```

This confirms several important things:

| Output           | Meaning                                                      |
| ---------------- | ------------------------------------------------------------ |
| `vm_name`        | VM was created as `dev-module-output-vm`                     |
| `vm_internal_ip` | VM received internal IP `10.50.1.2`                          |
| `vm_external_ip` | VM has no external IP                                        |
| `vm_subnet_key`  | VM selected the `app` subnet                                 |
| `vm_subnet_link` | VM consumed the app subnet self-link from the network module |

The VM output also showed:

```text
vm_selected_subnet_key = "app"
vm_selected_subnet_self_link = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
```

This proves that the VM was attached to the subnet created by the network module.

## Subnet Outputs

The subnet outputs showed:

```text
subnets = {
  "app" = {
    "cidr_range" = "10.50.1.0/24"
    "id" = "projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
    "name" = "dev-app-subnet"
    "region" = "asia-southeast2"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
  }
  "db" = {
    "cidr_range" = "10.50.2.0/24"
    "id" = "projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-db-subnet"
    "name" = "dev-db-subnet"
    "region" = "asia-southeast2"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-db-subnet"
  }
}
```

This confirms that the network module created both the app and db subnets.

## Firewall Outputs

The firewall outputs showed:

```text
firewall_rules = {
  "allow-iap-ssh" = {
    "id" = "projects/terraform-gcp-learning-lab/global/firewalls/dev-allow-iap-ssh"
    "name" = "dev-allow-iap-ssh"
    "source_ranges" = toset([
      "35.235.240.0/20",
    ])
    "target_tags" = toset([
      "iap-ssh",
    ])
  }
  "allow-internal" = {
    "id" = "projects/terraform-gcp-learning-lab/global/firewalls/dev-allow-internal"
    "name" = "dev-allow-internal"
    "source_ranges" = toset([
      "10.50.0.0/16",
    ])
    "target_tags" = toset(null) /* of string */
  }
}
```

The IAP SSH rule targets instances with the tag:

```text
iap-ssh
```

The VM also uses:

```hcl
vm_tags = ["iap-ssh"]
```

So the firewall rule is connected to the VM through network tags.

## Verify the VM

I can verify the VM using:

```bash
gcloud compute instances list --filter="name=dev-module-output-vm"
```

I can also inspect the VM network interface:

```bash
gcloud compute instances describe dev-module-output-vm \
  --zone=asia-southeast2-a \
  --format="value(networkInterfaces[0].subnetwork,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs)"
```

The expected result is:

```text
subnetwork: dev-app-subnet
internal IP: 10.50.1.2
external IP/accessConfigs: empty
```

This means the VM is private and does not have an external IP.

## Verify Remote State

Because this lab uses the GCS backend, the state is stored remotely.

I can verify it with:

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/06-gcp-vm-and-network-module/
```

Expected output:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/06-gcp-vm-and-network-module/default.tfstate
```

## Destroy

Because this is still a learning lab, I destroyed the resources after testing:

```bash
terraform destroy
```

Then I typed:

```text
yes
```

Terraform destroyed the resources managed by this lab.

## What I Learned

This lab helped me understand Terraform module composition more clearly.

In the previous lab, I had one child module:

```text
gcp-network
```

In this lab, I added another child module:

```text
gcp-vm
```

The most important lesson was not just creating a VM.

The important lesson was passing an output from one module into another module.

The flow is:

```text
gcp-network creates subnets
gcp-network outputs subnet self-links
root module selects the app subnet
root module passes the subnet self-link into gcp-vm
gcp-vm creates a VM in that subnet
```

The key Terraform expression is:

```hcl
module.network.subnets[var.vm_subnet_key].self_link
```

Breaking it down:

```text
module.network
```

means the network child module.

```text
.subnets
```

means the subnet output from that module.

```text
[var.vm_subnet_key]
```

means select one subnet from the subnet map.

```text
.self_link
```

means use the selected subnet self-link.

So if:

```hcl
vm_subnet_key = "app"
```

Terraform uses:

```hcl
module.network.subnets["app"].self_link
```

This is then passed into the VM module.

That is the main pattern I wanted to learn:

```text
module output -> root module -> another module input
```

## Next Step

The next logical step is to improve the VM access pattern.

Right now, the VM has no external IP and has an IAP SSH firewall rule.

The next lab could focus on testing private VM access through IAP, or improving the module further by adding:

- service account for the VM
- IAM binding for IAP SSH
- OS Login configuration
- startup script verification
- HTTP health check or internal-only web service testing
