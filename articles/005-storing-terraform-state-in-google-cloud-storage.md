Again with another journey of mine!
In my previous Terraform labs, I created Google Cloud resources using Terraform with local state. By default, Terraform stores state locally in a file called:

```text
terraform.tfstate
```

Previously, we are doing this locally, and now i want to try it in GCS (google cloud storage) to store my remote state.

In this article, I will move from local Terraform state to remote state using Google Cloud Storage. Thus, my goal is to use the remote state using Google Cloud Storage.

## What This Lab Creates

We will create:

- a Google Cloud Storage bucket for Terraform state
- a Terraform GCS backend configuration
- a custom VPC network
- a custom subnet
- a remote Terraform state file stored in GCS

My state bucket name is:

```text
terraform-gcp-learning-lab-terraform-state
```

The state path in the bucket is:

```text
terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/03-remote-state-gcs/default.tfstate
```

## Why Remote State Matters

Terraform state is important because it tracks the relationship between Terraform configuration and real infrastructure.

For example, when Terraform creates a VPC, it stores information about that VPC in the state file.

So, when i run:

```bash
terraform plan
```

Terraform compares:

1. my current Terraform configuration
2. the current state
3. the real infrastructure in Google Cloud

Then Terraform decides what needs to be created, changed, or destroyed.

This is why state management is important.

If I only store state locally, it becomes harder to collaborate, recover, or operate Terraform safely.

Using Google Cloud Storage as the backend helps move the state file away from my local laptop and into a remote location.

## Step 1: Set Environment Variables

First, I set the environment variables for my project, state bucket, and region.

```bash
export PROJECT_ID=terraform-gcp-learning-lab
export STATE_BUCKET="${PROJECT_ID}-terraform-state"
export REGION="asia-southeast2"
```

In my case:

```text
PROJECT_ID = terraform-gcp-learning-lab
STATE_BUCKET = terraform-gcp-learning-lab-terraform-state
REGION = asia-southeast2
```

I used `asia-southeast2` because this is the Jakarta region and currently I am in Jakarta.

## Step 2: Create the GCS Bucket

Next, I created the Google Cloud Storage bucket that will store the Terraform state.

```bash
gcloud storage buckets create gs://${STATE_BUCKET} \
  --project=${PROJECT_ID} \
  --location=${REGION} \
  --uniform-bucket-level-access
```

This creates a GCS bucket with uniform bucket-level access enabled.

Uniform bucket-level access means access control is managed at the bucket level using IAM, instead of mixing IAM and object-level ACLs.

## Step 3: Enable Bucket Versioning

After creating the bucket, I enabled versioning.

```bash
gcloud storage buckets update gs://${STATE_BUCKET} \
  --versioning
```

This is useful because Terraform state is important. So if you change it or remove it, you can go back to the previous version anytime you want.

If the state file is accidentally overwritten, bucket versioning can help provide a recovery path.

## Step 3: Enable Bucket Versioning

After creating the bucket, I enabled versioning.

```bash
gcloud storage buckets update gs://${STATE_BUCKET} \
  --versioning
```

This is useful because Terraform state is important.

If the state file is accidentally overwritten, bucket versioning can help provide a recovery path.

I created a new folder for this lab:

```bash
mkdir 03-remote-state-gcs
cd 03-remote-state-gcs
```

Then I created the Terraform files:

```bash
touch backend.tf main.tf variables.tf outputs.tf
```

The folder structure looks like this:

```text
03-remote-state-gcs/
├── backend.tf
├── main.tf
├── variables.tf
└── outputs.tf
```

## Step 5: Configure the GCS Backend

The backend configuration tells Terraform where to store state.

In `backend.tf`, I added:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/03-remote-state-gcs"
  }
}
```

The `bucket` is the GCS bucket name.

The `prefix` is the path inside the bucket where Terraform will store the state file.

In this lab, Terraform will store the state at:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/03-remote-state-gcs/default.tfstate
```

One important note:

Backend configuration cannot use normal Terraform variables like this:

```hcl
bucket = var.bucket_name
```

That is because Terraform needs to configure the backend before it evaluates variables.

So for this beginner lab, I hardcoded the bucket name directly inside `backend.tf`.

## Step 6: Create `variables.tf`

Next, I created the input variables.

```hcl
variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "The Google Cloud region where regional resources will be created."
  type        = string
  default     = "asia-southeast2"
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "remote-state-network"
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "remote-state-subnet"
}

variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.20.0.0/24"
}
```

The `project` variable does not have a default value.

This means Terraform will ask me to provide the project ID when running commands such as:

```bash
terraform plan
```

or:

```bash
terraform apply
```

## Step 7: Create `main.tf`

This is my `main.tf`:

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
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.subnet_cidr_range
}
```

This configuration creates two resources:

| Resource                             | Description           |
| ------------------------------------ | --------------------- |
| `google_compute_network.vpc_network` | Custom VPC network    |
| `google_compute_subnetwork.subnet`   | Subnet inside the VPC |

I set:

```hcl
auto_create_subnetworks = false
```

because I want to create a custom mode VPC.

That means the subnet is created explicitly by Terraform instead of being automatically created by Google Cloud.

## Step 8: Create `outputs.tf`

I also created a simple `outputs.tf` file to display useful information after the resources are created.

```hcl
output "vpc_network_name" {
  description = "The name of the VPC network."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "The ID of the VPC network."
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The name of the subnet."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "The CIDR range of the subnet."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}
```

These outputs make it easier to see selected infrastructure information after running `terraform apply`.

## Step 9: Initialize Terraform

Before applying the configuration, I initialized Terraform.

```bash
terraform init
```

This command initializes the working directory, downloads the provider, and configures the GCS backend.

The important part is this:

```text
Successfully configured the backend "gcs"!
```

This means Terraform is now configured to store state in Google Cloud Storage.

## Step 10: Format and Validate

After initialization, I formatted the Terraform files:

```bash
terraform fmt
```

Then I validated the configuration:

```bash
terraform validate
```

Expected output:

```text
Success! The configuration is valid.
```

## Step 11: Run Terraform Plan

Next, I reviewed the execution plan:

```bash
terraform plan
```

Because the `project` variable does not have a default value, Terraform asked me to enter it:

```text
var.project
  The Google Cloud project ID where resources will be created.

  Enter a value:
```

I entered:

```text
terraform-gcp-learning-lab
```

Terraform then generated a plan.

Expected result:

```text
Plan: 2 to add, 0 to change, 0 to destroy.
```

Terraform planned to create:

- one VPC network
- one subnet

## Step 12: Apply the Configuration

After reviewing the plan, I applied the configuration:

```bash
terraform apply
```

Terraform asked for the project value again.

I entered:

```text
terraform-gcp-learning-lab
```

Then Terraform asked for confirmation:

```text
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

I typed:

```text
yes
```

After the apply finished, Terraform created the VPC and subnet.

## Step 13: Verify the State File in GCS

After applying the configuration, I checked the bucket.

The state file was created under this path:

```text
terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/03-remote-state-gcs/default.tfstate
```

This confirms that Terraform state is now stored in Google Cloud Storage.

To check it using the CLI:

```bash
gcloud storage ls gs://${STATE_BUCKET}/terraform-gcp-learning-lab/03-remote-state-gcs/
```

Expected output:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/03-remote-state-gcs/default.tfstate
```

This is the key result of the lab.

The infrastructure is still managed by Terraform, but the state is no longer stored only as a local `terraform.tfstate` file.

## Step 14: Query the Outputs

I can still query outputs normally:

```bash
terraform output
```

Even though the state is remote, Terraform commands still work from my local terminal.

The difference is that Terraform reads and writes state from the GCS backend.

## Step 15: Destroy the Infrastructure

Because this is only a learning lab, I destroyed the resources after testing:

```bash
terraform destroy
```

Terraform asked for the project value again.

Then it showed the destroy plan.

I typed:

```text
yes
```

This destroyed the VPC and subnet managed by Terraform.

Important note:

This does not delete the GCS bucket because the bucket was created manually using `gcloud`, not by this Terraform configuration.

## What I Learned

In this lab, I learned that Terraform state is one of the most important parts of Terraform.

Previously, my Terraform state was stored locally.

After this lab, my Terraform state is stored remotely in Google Cloud Storage.

## Next Step

This lab still asks me to enter the `project` variable manually.

In the next article, I want to improve the workflow by using:

- `terraform.tfvars`
- cleaner variable values
- safer GitHub patterns using `terraform.tfvars.example`

That should make the Terraform workflow more practical and less repetitive.
