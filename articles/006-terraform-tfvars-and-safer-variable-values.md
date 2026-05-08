# Terraform tfvars and Safer Variable Values

In the previous lab, I configured Terraform remote state using Google Cloud Storage. I like that, but there was still one part of the workflow that i think can be automated.

Every time I ran:

```bash
terraform plan
```

or:

```bash
terraform apply
```

Terraform asked me to manually enter the Google Cloud project ID. I don't like that. So in this lab, I will improve the configuration by introducing:

- `terraform.tfvars`
- `terraform.tfvars.example`
- safer GitHub patterns
- variable validation
- cleaner environment-based naming

The goal is not only to make Terraform stop asking for the project ID manually.

The goal is to make the configuration cleaner, safer, and closer to how Terraform is usually managed in a real project.

Reference: [terraform website](https://developer.hashicorp.com/terraform/language/values/variables)

## Goals

The goals for this lab are simple:

1. Use `terraform.tfvars` to provide local variable values.
2. Stop typing the project ID manually during `terraform plan` and `terraform apply`.
3. Use `terraform.tfvars.example` as a safe template for GitHub.
4. Keep the real `terraform.tfvars` file out of version control.
5. Add validation rules to prevent bad variable values.
6. Continue using Google Cloud Storage as the remote backend.

## Previous Problem

In the previous configuration, I declared the `project` variable like this:

```hcl
variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
}
```

Because this variable does not have a default value, Terraform asked me to enter it manually.

For example:

```bash
terraform plan
```

Terraform would ask:

```text
var.project
  The Google Cloud project ID where resources will be created.

  Enter a value:
```

Then I had to type:

```text
terraform-gcp-learning-lab
```

The same thing happened when running:

```bash
terraform apply
```

This works, but it is repetitive.

A better way is to provide variable values using a `terraform.tfvars` file.

## What is `terraform.tfvars`?

`terraform.tfvars` is a variable definition file.

Instead of manually typing variable values in the terminal, I can store those values in a file.

Terraform automatically loads a file named:

```text
terraform.tfvars
```

when running commands like:

```bash
terraform plan
terraform apply
terraform destroy
```

This means I can define the values once and reuse them across Terraform commands.

## Final Folder Structure

For this lab, my folder structure looks like this:

```text
04-tfvars-safe-variable-values/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── terraform.tfvars.example
└── README.md
```

However, for GitHub, I should only commit:

```text
04-tfvars-safe-variable-values/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars.example
└── README.md
```

I should not commit:

```text
terraform.tfvars
```

because real `.tfvars` files can contain environment-specific values or sensitive values.

## Step 1: Configure the GCS Backend

Because the previous lab already created a GCS bucket for Terraform state, I reused the same bucket.

My state bucket is:

```text
terraform-gcp-learning-lab-terraform-state
```

In `backend.tf`, I added:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/04-tfvars-safe-variable-values"
  }
}
```

The important part here is the `prefix`.

```hcl
prefix = "terraform-gcp-learning-lab/04-tfvars-safe-variable-values"
```

This gives the lab its own remote state path.

I do not want this lab to share the same state file as the previous remote state lab. Each lab should have its own isolated state path to avoid state collision.

## Step 2: Create `variables.tf`

Next, I created `variables.tf`.

This time, I did not only declare basic variables. I also added:

- descriptions
- types
- default values
- validation rules

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
  description = "The Google Cloud region where regional resources will be created."
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
  default     = "tfvars-network"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.network_name))
    error_message = "Network name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."
  }
}

variable "subnet_name" {
  description = "Base name of the subnet."
  type        = string
  default     = "tfvars-subnet"

  validation {
    condition     = can(regex("^[a-z]([-a-z0-9]*[a-z0-9])?$", var.subnet_name))
    error_message = "Subnet name must use lowercase letters, numbers, and hyphens. It must start with a letter and end with a letter or number."
  }
}

variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.30.0.0/24"

  validation {
    condition     = can(cidrhost(var.subnet_cidr_range, 0))
    error_message = "Subnet CIDR range must be a valid CIDR block, for example 10.30.0.0/24."
  }
}
```

This makes the variables more self-documenting.

For example, this is better:

```hcl
variable "region" {
  description = "The Google Cloud region where regional resources will be created."
  type        = string
  default     = "asia-southeast2"
}
```

than only writing:

```hcl
variable "region" {}
```

The validation rules are also useful because they help catch bad values before Terraform creates or changes infrastructure.

## Step 3: Create `main.tf`

Next, I created `main.tf`.

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

resource "google_compute_network" "vpc_network" {
  name                    = "${var.environment}-${var.network_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.environment}-${var.subnet_name}"
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.subnet_cidr_range
}
```

This configuration creates:

| Resource                             | Description             |
| ------------------------------------ | ----------------------- |
| `google_compute_network.vpc_network` | A custom VPC network    |
| `google_compute_subnetwork.subnet`   | A subnet inside the VPC |

The naming is now controlled by variables.

For example:

```hcl
name = "${var.environment}-${var.network_name}"
```

If:

```hcl
environment  = "dev"
network_name = "tfvars-network"
```

then the final VPC name becomes:

```text
dev-tfvars-network
```

This is better than hardcoding one static name for every environment.

## Step 4: Create `outputs.tf`

I also created an `outputs.tf` file.

```hcl
output "environment" {
  description = "The environment used for this lab."
  value       = var.environment
}

output "vpc_network_name" {
  description = "The final VPC network name."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "The VPC network ID."
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The final subnet name."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "The subnet CIDR range."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "lab_summary" {
  description = "Summary of the Terraform tfvars lab."

  value = {
    project     = var.project
    environment = var.environment
    region      = var.region
    network     = google_compute_network.vpc_network.name
    subnet      = google_compute_subnetwork.subnet.name
    cidr        = google_compute_subnetwork.subnet.ip_cidr_range
  }
}
```

The `lab_summary` output is useful because it shows the key values from the lab in one structured output.

## Step 5: Create `terraform.tfvars`

Now I created the real local values file:

```bash
touch terraform.tfvars
```

Inside `terraform.tfvars`, I added:

```hcl
project           = "terraform-gcp-learning-lab"
region            = "asia-southeast2"
environment       = "dev"
network_name      = "tfvars-network"
subnet_name       = "tfvars-subnet"
subnet_cidr_range = "10.30.0.0/24"
```

This is the file that Terraform will automatically read.

Because of this file, Terraform no longer needs to ask me to enter the `project` value manually.

## Step 6: Create `terraform.tfvars.example`

The real `terraform.tfvars` file should not be committed to GitHub.

However, I still want other people to understand what values are needed to recreate the lab.

So I created:

```bash
touch terraform.tfvars.example
```

Inside `terraform.tfvars.example`, I added:

```hcl
project           = "your-gcp-project-id"
region            = "asia-southeast2"
environment       = "dev"
network_name      = "tfvars-network"
subnet_name       = "tfvars-subnet"
subnet_cidr_range = "10.30.0.0/24"
```

This file is safe to commit because it does not contain my actual project-specific values.

The pattern is:

```text
Commit terraform.tfvars.example.
Do not commit terraform.tfvars.
```

## Step 7: Update `.gitignore`

At the root of my GitHub repository, I updated `.gitignore`.

```gitignore
# Terraform local files
.terraform/
*.tfstate
*.tfstate.*

# Terraform variable files that may contain sensitive or environment-specific values
*.tfvars
*.tfvars.json

# Keep example variable files
!*.tfvars.example

# Crash logs
crash.log
crash.*.log

# macOS
.DS_Store
```

This makes Git ignore real `.tfvars` files but still allow `.tfvars.example` files.

This is important because `.tfvars` files may contain values that should not be exposed publicly.

## Step 8: Initialize Terraform

After preparing the files, I initialized Terraform:

```bash
terraform init
```

Expected result:

```text
Successfully configured the backend "gcs"!
```

This means Terraform is using the GCS backend for remote state.

## Step 9: Format and Validate

Then I formatted the files:

```bash
terraform fmt
```

After that, I validated the configuration:

```bash
terraform validate
```

Expected output:

```text
Success! The configuration is valid.
```

## Step 10: Run `terraform plan`

Now I ran:

```bash
terraform plan
```

This time, Terraform did not ask me to manually enter the project value.

That is because Terraform automatically loaded the value from:

```text
terraform.tfvars
```

Expected plan summary:

```text
Plan: 2 to add, 0 to change, 0 to destroy.
```

Terraform planned to create:

- one custom VPC network
- one subnet

This is the first improvement of the lab.

The workflow is now cleaner because the repeated variable values are stored in a local `.tfvars` file.

## Step 11: Test Variable Validation

Before applying the configuration, I tested the validation rules.

First, I intentionally changed the environment value in `terraform.tfvars`.

```hcl
environment = "development"
```

Then I ran:

```bash
terraform plan
```

Terraform returned a validation error because the accepted values are only:

```text
dev
staging
prod
```

The expected error is:

```text
Environment must be one of: dev, staging, or prod.
```

After testing, I changed it back:

```hcl
environment = "dev"
```

Then I tested the subnet CIDR validation.

I changed:

```hcl
subnet_cidr_range = "10.30.0.0/24"
```

to:

```hcl
subnet_cidr_range = "not-a-cidr"
```

Then I ran:

```bash
terraform plan
```

Terraform returned an error because the value was not a valid CIDR block.

The expected error is:

```text
Subnet CIDR range must be a valid CIDR block, for example 10.30.0.0/24.
```

After testing, I changed it back:

```hcl
subnet_cidr_range = "10.30.0.0/24"
```

This is the second improvement of the lab.

Terraform does not only accept values from `terraform.tfvars`. It can also validate whether the values are acceptable before creating infrastructure.

## Step 12: Apply the Configuration

After confirming that the validation works, I applied the configuration:

```bash
terraform apply
```

Terraform showed the execution plan and asked for confirmation.

I typed:

```text
yes
```

Expected result:

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Terraform also displayed the outputs:

```text
Outputs:

environment = "dev"
subnet_cidr_range = "10.30.0.0/24"
subnet_name = "dev-tfvars-subnet"
vpc_network_name = "dev-tfvars-network"

lab_summary = {
  "cidr" = "10.30.0.0/24"
  "environment" = "dev"
  "network" = "dev-tfvars-network"
  "project" = "terraform-gcp-learning-lab"
  "region" = "asia-southeast2"
  "subnet" = "dev-tfvars-subnet"
}
```

The exact output may look slightly different depending on the project and Terraform output order.

## Step 13: Verify Remote State

Because this lab uses the GCS backend, I verified that the remote state was created in the correct path.

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/04-tfvars-safe-variable-values/
```

Expected output:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/04-tfvars-safe-variable-values/default.tfstate
```

This confirms that the lab still uses remote state, but now with cleaner variable handling.

## Step 14: Query Outputs

I can query all outputs:

```bash
terraform output
```

I can also query the summary output:

```bash
terraform output lab_summary
```

Or get the output in JSON format:

```bash
terraform output -json
```

The JSON output can be useful when Terraform output needs to be consumed by another tool or script.

## Step 15: Destroy the Infrastructure

Because this is only a learning lab, I destroyed the resources after testing:

```bash
terraform destroy
```

Terraform showed the destroy plan and asked for confirmation.

I typed:

```text
yes
```

Expected result:

```text
Destroy complete! Resources: 2 destroyed.
```

The GCS bucket is not destroyed because it was not created by this Terraform configuration.

## What I Learned

The main lesson from this lab is that Terraform variable management is not only about convenience.

At first, I only wanted to avoid typing the project ID repeatedly.

But after adding `terraform.tfvars`, `terraform.tfvars.example`, `.gitignore`, and validation rules, I realized that variable management also affects:

- safety
- repeatability
- collaboration
- repository hygiene
- infrastructure naming consistency

## Next Step

This lab improved the variable workflow.

The next logical step is to make the Terraform configuration reusable by introducing modules.

So far, every lab defines resources directly in the root configuration.

In the next lab, I want to learn how to turn the VPC and subnet configuration into a reusable Terraform module.
