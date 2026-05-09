# Building a Reusable VPC, Subnets, and Firewall Rules Module

In the previous Terraform labs, I created Google Cloud resources directly from the root configuration.

That worked, but the structure was still quite simple.

Every resource was defined directly inside the main Terraform configuration. For a small lab, that is fine. But as the infrastructure grows, putting everything in one root configuration can become harder to maintain.

So in this lab, I started learning Terraform modules.

The goal is to turn the previous VPC and subnet configuration into a reusable local module.

But instead of only creating one VPC and one subnet, I made the lab slightly more practical by creating:

- one custom VPC network
- two subnets
- two firewall rules
- reusable module inputs
- module outputs
- remote state using Google Cloud Storage

## What is a Terraform Module?

A Terraform module is a collection of Terraform configuration files that are managed together.

In simple terms, a module is like a reusable infrastructure component.

For this lab, I created a local module called:

```text
modules/gcp-network
```

This module is responsible for creating the GCP network resources.

The root configuration calls that module and passes values into it.

## Root Module vs Child Module

The folder where I run Terraform commands is the root module.

In this lab, the root module is:

```text
05-gcp-network-module/
```

The reusable child module is:

```text
05-gcp-network-module/modules/gcp-network/
```

The root module is the entry point.

The child module is the reusable implementation.

The mental model is:

```text
Root module = caller
Child module = reusable implementation
Child module variables = function parameters
Child module outputs = return values
```

Since I have written JavaScript before, this feels similar to calling a function.

The root module passes values into the child module, and the child module creates the infrastructure based on those values.

## Final Folder Structure

The folder structure for this lab is:

```text
05-gcp-network-module/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── terraform.tfvars.example
└── modules/
    └── gcp-network/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

For GitHub, I only commit:

```text
05-gcp-network-module/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── modules/
    └── gcp-network/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

I do not commit:

```text
terraform.tfvars
.terraform/
terraform.tfstate
```

## Backend Configuration

This lab still uses remote state with Google Cloud Storage.

In `backend.tf`, I configured the GCS backend:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/05-gcp-network-module"
  }
}
```

The bucket is:

```text
terraform-gcp-learning-lab-terraform-state
```

The state path is:

```text
terraform-gcp-learning-lab/05-gcp-network-module/default.tfstate
```

Each lab should have its own state prefix.

This avoids accidentally mixing state from different labs.

## Root `main.tf`

The root `main.tf` configures the provider and calls the child module.

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
```

The most important part is this:

```hcl
module "network" {
  source = "./modules/gcp-network"
}
```

This tells Terraform to use the local module inside:

```text
modules/gcp-network
```

The root module passes values such as:

```hcl
environment
region
network_name
subnets
firewall_rules
```

into the child module.

## Root `variables.tf`

In the root `variables.tf`, I declared the values that the lab accepts.

```hcl
variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "The project variable must not be empty."
  }
}

variable "region" {
  description = "Default Google Cloud region for regional resources."
  type        = string
  default     = "asia-southeast2"

  validation {
    condition     = contains(["asia-southeast2", "asia-southeast1", "us-central1"], var.region)
    error_message = "Region must be one of: asia-southeast2, asia-southeast1, or us-central1."
  }
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, or prod."
  }
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
  default     = "network-module"

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
      can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", subnet_key)) &&
      can(cidrhost(subnet.cidr_range, 0))
    ])

    error_message = "Each subnet key must be a valid lowercase name, and each cidr_range must be a valid CIDR block."
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
      ports    = optional(list(string))
    }))
  }))

  default = {}

  validation {
    condition = alltrue(flatten([
      for rule_name, rule in var.firewall_rules : [
        for source_range in rule.source_ranges :
        can(cidrhost(source_range, 0))
      ]
    ]))

    error_message = "Every firewall source range must be a valid CIDR block."
  }
}
```

This is more advanced than the previous labs because I am no longer passing only simple strings.

For `subnets`, I used:

```hcl
map(object({
  cidr_range = string
  region     = optional(string)
}))
```

For `firewall_rules`, I used a more complex object structure because each firewall rule can contain:

- description
- source ranges
- target tags
- allowed protocols and ports

## Child Module `variables.tf`

Inside the child module, I also declared the variables that the module expects.

File:

```text
modules/gcp-network/variables.tf
```

```hcl
variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "region" {
  description = "Default Google Cloud region for regional resources."
  type        = string
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create inside the VPC."
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

At first, having variables in both the root module and child module felt repetitive.

But the purpose is different.

The root variables receive values from the outside, usually from `terraform.tfvars`.

The child module variables define the input contract of the reusable module.

The flow is:

```text
terraform.tfvars
      ↓
root variables.tf
      ↓
root main.tf module block
      ↓
child module variables.tf
      ↓
child module main.tf resources
```

## Child Module `main.tf`

Inside the child module, I defined the actual GCP resources.

File:

```text
modules/gcp-network/main.tf
```

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

There are several important concepts here.

## Using `locals`

I used a local value to build the final network name:

```hcl
locals {
  final_network_name = "${var.environment}-${var.network_name}"
}
```

This means if:

```hcl
environment  = "dev"
network_name = "network-module"
```

then the final network name becomes:

```text
dev-network-module
```

## Creating Multiple Subnets with `for_each`

Instead of creating subnet resources one by one, I used `for_each`.

```hcl
resource "google_compute_subnetwork" "subnets" {
  for_each = var.subnets

  name          = "${var.environment}-${each.key}-subnet"
  region        = coalesce(each.value.region, var.region)
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = each.value.cidr_range
}
```

This lets Terraform create multiple subnet resources from a map.

For example, in my `terraform.tfvars`, I defined:

```hcl
subnets = {
  app = {
    cidr_range = "10.40.1.0/24"
  }

  db = {
    cidr_range = "10.40.2.0/24"
  }
}
```

Terraform then creates:

```text
dev-app-subnet
dev-db-subnet
```

This is better than duplicating two separate `google_compute_subnetwork` blocks.

## Creating Firewall Rules with `for_each`

I also used `for_each` for firewall rules.

```hcl
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

This allows me to define firewall rules from a map instead of hardcoding each rule directly in the module.

## Using a Dynamic Block

The firewall rule uses a dynamic block:

```hcl
dynamic "allow" {
  for_each = each.value.allow

  content {
    protocol = allow.value.protocol
    ports    = allow.value.ports
  }
}
```

I used this because a firewall rule can allow multiple protocols.

For example, the internal rule allows:

- TCP
- UDP
- ICMP

Instead of hardcoding multiple `allow` blocks, the dynamic block generates them from the input value.

## Child Module Outputs

The child module also exposes outputs.

File:

```text
modules/gcp-network/outputs.tf
```

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

These outputs allow the root module to consume and display the values created inside the child module.

## Root Outputs

The root module then exposes selected module outputs.

File:

```text
outputs.tf
```

```hcl
output "network_name" {
  description = "The VPC network name created by the network module."
  value       = module.network.network_name
}

output "network_id" {
  description = "The VPC network ID created by the network module."
  value       = module.network.network_id
}

output "subnets" {
  description = "Subnets created by the network module."
  value       = module.network.subnets
}

output "firewall_rules" {
  description = "Firewall rules created by the network module."
  value       = module.network.firewall_rules
}

output "lab_summary" {
  description = "Summary of this module-based network lab."

  value = {
    project        = var.project
    environment    = var.environment
    region         = var.region
    network_name   = module.network.network_name
    subnet_count   = length(module.network.subnets)
    firewall_count = length(module.network.firewall_rules)
  }
}
```

The root output references the child module output like this:

```hcl
module.network.network_name
```

This means:

```text
Get the network_name output from the network module.
```

## `terraform.tfvars`

For local values, I used `terraform.tfvars`.

```hcl
project      = "terraform-gcp-learning-lab"
region       = "asia-southeast2"
environment  = "dev"
network_name = "network-module"

subnets = {
  app = {
    cidr_range = "10.40.1.0/24"
  }

  db = {
    cidr_range = "10.40.2.0/24"
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
    source_ranges = ["10.40.0.0/16"]

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

```

This creates:

- one VPC
- two subnets
- two firewall rules

The IAP SSH source range is:

```text
35.235.240.0/20
```

This is used for Identity-Aware Proxy TCP forwarding.

I used this instead of opening SSH to:

```text
0.0.0.0/0
```

because opening SSH to the whole internet is not a good habit.

## Initialize Terraform

After preparing the files, I ran:

```bash
terraform init
```

Because this lab uses a module, Terraform also initialized the module.

The expected output includes something like:

```text
Initializing modules...
- network in modules/gcp-network
```

This is different from the previous labs.

Previously, Terraform initialized only the backend and provider.

Now, Terraform also recognizes the local child module.

## Format and Validate

Because this lab has Terraform files inside the module folder, I used:

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

## Plan

Next, I ran:

```bash
terraform plan
```

The expected plan was:

```text
Plan: 5 to add, 0 to change, 0 to destroy.
```

Terraform planned to create:

```text
module.network.google_compute_network.vpc_network
module.network.google_compute_subnetwork.subnets["app"]
module.network.google_compute_subnetwork.subnets["db"]
module.network.google_compute_firewall.ingress_rules["allow-iap-ssh"]
module.network.google_compute_firewall.ingress_rules["allow-internal"]
```

This is an important difference.

Previously, resource addresses looked like this:

```text
google_compute_network.vpc_network
```

Now, because the resource is created inside a module, the address starts with:

```text
module.network
```

For example:

```text
module.network.google_compute_network.vpc_network
```

This means the resource is managed inside the `network` module.

## Apply

After reviewing the plan, I applied the configuration:

```bash
terraform apply
```

Then I typed:

```text
yes
```

Terraform created the resources successfully.

## Terraform Output

After the apply completed, I checked the outputs:

```bash
terraform output
```

The result was:

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
      "10.40.0.0/16",
    ])
    "target_tags" = toset(null) /* of string */
  }
}
lab_summary = {
  "environment" = "dev"
  "firewall_count" = 2
  "network_name" = "dev-network-module"
  "project" = "terraform-gcp-learning-lab"
  "region" = "asia-southeast2"
  "subnet_count" = 2
}
network_id = "projects/terraform-gcp-learning-lab/global/networks/dev-network-module"
network_name = "dev-network-module"
subnets = {
  "app" = {
    "cidr_range" = "10.40.1.0/24"
    "id" = "projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
    "name" = "dev-app-subnet"
    "region" = "asia-southeast2"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-app-subnet"
  }
  "db" = {
    "cidr_range" = "10.40.2.0/24"
    "id" = "projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-db-subnet"
    "name" = "dev-db-subnet"
    "region" = "asia-southeast2"
    "self_link" = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/regions/asia-southeast2/subnetworks/dev-db-subnet"
  }
}
```

The output confirms that Terraform created:

- one VPC network
- two subnets
- two firewall rules

The `lab_summary` output is especially useful because it gives a quick summary:

```text
firewall_count = 2
subnet_count   = 2
network_name   = "dev-network-module"
```

## Verify the VPC in Google Cloud

I also verified the VPC using the Google Cloud CLI.

```bash
gcloud compute networks list --filter="name=dev-network-module"
```

Output:

```text
NAME                SUBNET_MODE  BGP_ROUTING_MODE  IPV4_RANGE  GATEWAY_IPV4  INTERNAL_IPV6_RANGE
dev-network-module  CUSTOM       REGIONAL
```

This confirms that the VPC network was created in custom subnet mode.

## Verify the Subnets

Then I checked the subnets:

```bash
gcloud compute networks subnets list \
  --filter="network:dev-network-module"
```

Output:

```text
NAME            REGION           NETWORK             RANGE         STACK_TYPE  IPV6_ACCESS_TYPE  INTERNAL_IPV6_PREFIX  EXTERNAL_IPV6_PREFIX  UTILIZATION_DETAILS
dev-app-subnet  asia-southeast2  dev-network-module  10.40.1.0/24  IPV4_ONLY
dev-db-subnet   asia-southeast2  dev-network-module  10.40.2.0/24  IPV4_ONLY
```

This confirms that both subnets were created:

| Subnet           | CIDR Range     |
| ---------------- | -------------- |
| `dev-app-subnet` | `10.40.1.0/24` |
| `dev-db-subnet`  | `10.40.2.0/24` |

## Verify Remote State

Because this lab uses the GCS backend, I verified the remote state file:

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/05-gcp-network-module/
```

Output:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/05-gcp-network-module/default.tfstate
```

This confirms that the Terraform state is stored in Google Cloud Storage.

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

The GCS state bucket was not destroyed because it was created outside this Terraform configuration.

## What I Learned

This lab helped me understand Terraform modules much better.

Previously, I created infrastructure directly in the root configuration.

Now, I separated the configuration into two layers:

```text
Root module = decides what to deploy
Child module = defines how to deploy it
```

The root module calls the child module:

```hcl
module "network" {
  source = "./modules/gcp-network"
}
```

The child module creates the actual resources:

- VPC
- subnets
- firewall rules
