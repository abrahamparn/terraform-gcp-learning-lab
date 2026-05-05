# Terraform Variables: Cleaning Up My First GCP VPC Configuration

In my previous Terraform article, I created my first Terraform-managed Google Cloud resource: a simple VPC network.

The first version worked, but the configuration was still very basic. As someone who has written a lot of JavaScript code, one thing immediately felt uncomfortable: too many values were hardcoded directly inside `main.tf`.

That made me wonder:

> There should be something similar to variables in Terraform, right?

After checking Terraform’s documentation, the answer is yes.

Terraform supports input variables, which allow configuration values to be reused and changed without directly modifying the main infrastructure logic.

In this article, I will improve the previous Terraform configuration by introducing:

- `variables.tf`
- input variables
- default values
- variable usage inside `main.tf`

Reference: [Terraform GCP variables tutorial](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-variables)

## Previous Configuration

To recap, this was the previous `main.tf` configuration:

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
  project = "<PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

This configuration works.

However, several values are hardcoded directly inside the provider block:

```hcl
project = "<PROJECT_ID>"
region  = "us-central1"
zone    = "us-central1-c"
```

For a small lab, this is acceptable.

But as the configuration grows, hardcoded values become harder to maintain. If I want to change the project, region, or zone, I need to edit the source configuration directly.

A cleaner approach is to declare these values as variables.

## Creating `variables.tf`

First, create a new file called `variables.tf`.

```bash
touch variables.tf
```

Then add the following variable definitions:

```hcl
variable "project" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}
```

The file name `variables.tf` is a common convention.

Technically, Terraform reads all `.tf` files in the current working directory. However, separating variables into `variables.tf` makes the configuration easier to understand and maintain.

## Understanding the Variables

### `project`

```hcl
variable "project" {}
```

The `project` variable does not have a default value.

This means Terraform will ask for the value when we run a command that needs it, such as:

```bash
terraform plan
```

or:

```bash
terraform apply
```

This is useful because the Google Cloud project ID may be different depending on the user or environment.

### `region`

```hcl
variable "region" {
  default = "us-central1"
}
```

The `region` variable has a default value.

If I do not provide another value, Terraform will use:

```text
us-central1
```

### `zone`

```hcl
variable "zone" {
  default = "us-central1-c"
}
```

The `zone` variable also has a default value.

For this simple VPC lab, the zone is not very important because a VPC network is a global resource in Google Cloud.

However, keeping the zone in the provider configuration is useful because future resources, such as Compute Engine instances, may need it.

## Updating `main.tf` to Use Variables

Now we can update `main.tf` to use the variables.

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
  zone    = var.zone
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

The important change is inside the provider block:

```hcl
project = var.project
region  = var.region
zone    = var.zone
```

Terraform uses the `var.<variable_name>` syntax to reference input variables.

For example:

```hcl
var.project
```

means Terraform will use the value provided for the `project` variable.

## Running Terraform Apply

After updating the configuration, run:

```bash
terraform fmt
```

Then validate the configuration:

```bash
terraform validate
```

If the configuration is valid, the output should look like this:

```bash
Success! The configuration is valid.
```

Next, run:

```bash
terraform apply
```

Because the `project` variable does not have a default value, Terraform will ask for it:

```bash
var.project
  Enter a value:
```

Enter your Google Cloud project ID.

Terraform will then show the execution plan and ask for confirmation:

```bash
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type:

```bash
yes
```

Example output:

```bash
google_compute_network.vpc_network: Creating...
google_compute_network.vpc_network: Still creating... [00m10s elapsed]
google_compute_network.vpc_network: Still creating... [00m20s elapsed]
google_compute_network.vpc_network: Still creating... [00m30s elapsed]
google_compute_network.vpc_network: Still creating... [00m40s elapsed]
google_compute_network.vpc_network: Creation complete after 43s [id=projects/terraform-gcp-learning-lab/global/networks/terraform-network]
```

At this point, Terraform has created the VPC network using values from the input variables.

## Destroying the Infrastructure

Because this is only a learning lab, I destroyed the resource after testing.

Run:

```bash
terraform destroy
```

Terraform will ask for the `project` variable again if it was not provided through another method.

Then Terraform will show the destroy plan and ask for confirmation.

Type:

```bash
yes
```

This removes the VPC network managed by this Terraform configuration.

## What Changed?

Previously, the provider configuration looked like this:

```hcl
provider "google" {
  project = "<PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}
```

Now it looks like this:

```hcl
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
```

The configuration is still simple, but it is now cleaner.

Instead of hardcoding every value inside `main.tf`, Terraform can read those values from input variables.

## What I Learned

From this lab, I learned that Terraform variables help separate configuration values from infrastructure logic.

The key idea is simple:

```text
main.tf defines what Terraform should create.
variables.tf defines what values Terraform can accept.
```

This makes the configuration easier to reuse and modify.

The most important distinction for me is that `variables.tf` declares variables, but it does not always provide the actual values.

If a variable has a default value, Terraform can use it automatically.

If a variable does not have a default value, Terraform will ask for the value during execution.

## Next Step

This article only introduced basic input variables.

In the next article, I want to continue improving this configuration by learning:

- how to provide variable values using `terraform.tfvars`
- how to avoid typing the project ID repeatedly
- how to expose useful resource information using Terraform outputs

That should make the configuration more practical and easier to reuse.
