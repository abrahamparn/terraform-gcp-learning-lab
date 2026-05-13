# CI/CD for Terraform on GCP: Plan on Pull Request, Apply with Approval, No Static Keys

Hi guys, so this will be my last lab.

In the previous labs, I used Terraform from my local machine.
The workflow was simple:

```text
local terminal -> terraform plan -> terraform apply
```

That worked for learning, but it is not how I want to manage infrastructure changes in a more professional setup.

For this lab, I wanted to move Terraform execution into GitHub Actions.

The target workflow is:

```text
Pull Request -> terraform fmt -> terraform validate -> terraform plan
Manual Approval -> terraform apply
```

The main goal is not only automation.

The main goal is infrastructure change control.

In this lab, I built a Terraform CI/CD workflow using:

- GitHub Actions
- Google Cloud Workload Identity Federation
- Terraform remote state in Google Cloud Storage
- `terraform fmt -check`
- `terraform validate`
- `terraform plan`
- manual `terraform apply`
- no downloaded service account JSON key

The key idea is:

> Terraform should not only create infrastructure. Terraform changes should also be reviewed before they are applied.

## Why This Lab Matters

Infrastructure as Code without review is dangerous.

Why only application code that needs review? why not Terraform? Thus, A better workflow is:

```text
write Terraform code
open pull request
run terraform fmt and validate
run terraform plan
review the change
apply only after approval
```

This makes Terraform closer to a professional engineering workflow.

## Why Workload Identity Federation?

One important decision in this lab was to avoid using a service account JSON key.

Instead, I used Workload Identity Federation.

The authentication flow is:

```text
GitHub Actions OIDC token
  ↓
Google Workload Identity Provider
  ↓
Google service account impersonation
  ↓
Terraform can access Google Cloud
```

This means I do not need to download a long-lived service account key and store it in GitHub Secrets.

For this lab, GitHub Actions impersonates a Google Cloud service account through Workload Identity Federation.

Reference:

https://github.com/google-github-actions/auth

https://cloud.google.com/blog/products/identity-security/enabling-keyless-authentication-from-github-actions

## What This Lab Creates

The infrastructure itself is intentionally simple.

This lab creates:

- one custom VPC network
- one subnet
- remote Terraform state in Google Cloud Storage

Why simple?

Because the focus of this lab is not infrastructure complexity.

The focus is the Terraform delivery workflow.

I wanted the CI/CD workflow to be easy to debug before applying it to a bigger project such as my production-lite GCP web platform.

## Folder Structure

The folder structure is:

```text
terraform-gcp-learning-lab/
├── .github/
│   └── workflows/
│       ├── lab-09-terraform-plan.yml
│       └── lab-09-terraform-apply.yml
└── 09-terraform-cicd-github-actions/
    ├── backend.tf
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── README.md
```

The Terraform code lives inside:

```text
09-terraform-cicd-github-actions/
```

The GitHub Actions workflows live inside:

```text
.github/workflows/
```

## Terraform Backend

The backend uses Google Cloud Storage.

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/09-terraform-cicd-github-actions"
  }
}
```

This keeps the state for this lab separate from the previous labs.

The expected state path is:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/09-terraform-cicd-github-actions/default.tfstate
```

## Terraform Configuration

The Terraform configuration creates a small VPC and subnet.

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

}
```

The expected resources are:

```text
google_compute_network.vpc_network
google_compute_subnetwork.subnet
```

## Variables

The root variables are defined in `variables.tf`.

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
  description = "Google Cloud region for regional resources."
  type        = string
  default     = "asia-southeast2"
}

variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
  default     = "dev"
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
  default     = "cicd-network"
}

variable "subnet_name" {
  description = "Base name of the subnet."
  type        = string
  default     = "cicd-subnet"
}

variable "subnet_cidr_range" {
  description = "CIDR range for the subnet."
  type        = string
  default     = "10.90.1.0/24"
}
```

The `project` variable does not have a default value.

That is intentional.

I do not want to hardcode the Google Cloud project ID inside the Terraform configuration.

In GitHub Actions, I pass the value using:

```bash
-var="project=${{ vars.GCP_PROJECT_ID }}"
```

## GitHub Repository Variables

In GitHub, I added repository variables under:

```text
Settings -> Secrets and variables -> Actions -> Variables
```

The variables are:

| Name                             | Example Value                                                                                     |
| -------------------------------- | ------------------------------------------------------------------------------------------------- |
| `GCP_PROJECT_ID`                 | `terraform-gcp-learning-lab`                                                                      |
| `GCP_REGION`                     | `asia-southeast2`                                                                                 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT`            | `terraform-cicd@PROJECT_ID.iam.gserviceaccount.com`                                               |
| `TF_WORKING_DIR`                 | `09-terraform-cicd-github-actions`                                                                |
| `TF_VERSION`                     | `1.15.1`                                                                                          |

These are repository variables, not service account keys.

There is no downloaded JSON key.

## Plan Workflow

The plan workflow runs on pull request.

File:

```text
.github/workflows/lab-09-terraform-plan.yml
```

```yaml
name: Lab 09 - Terraform Plan

on:
  pull_request:
    paths:
      - "09-terraform-cicd-github-actions/**"
      - ".github/workflows/lab-09-terraform-plan.yml"

permissions:
  contents: read
  id-token: write
  pull-requests: read

env:
  TF_IN_AUTOMATION: "true"
  TF_INPUT: "false"

jobs:
  terraform-plan:
    name: Terraform fmt, validate, and plan
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: ${{ vars.TF_WORKING_DIR }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud using WIF
        uses: google-github-actions/auth@v3
        with:
          project_id: ${{ vars.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v4
        with:
          terraform_version: ${{ vars.TF_VERSION }}

      - name: Terraform fmt check
        run: terraform fmt -check -recursive

      - name: Terraform init
        run: terraform init -input=false

      - name: Terraform validate
        run: terraform validate

      - name: Terraform plan
        run: |
          terraform plan \
            -input=false \
            -no-color \
            -var="project=${{ vars.GCP_PROJECT_ID }}" \
            -var="region=${{ vars.GCP_REGION }}"
```

The important part is:

```yaml
permissions:
  contents: read
  id-token: write
```

The `id-token: write` permission is required for GitHub Actions to request an OIDC token for Workload Identity Federation.

## Apply Workflow

The apply workflow is manually triggered.

File:

```text
.github/workflows/lab-09-terraform-apply.yml
```

```yaml
name: Lab 09 - Terraform Apply

on:
  workflow_dispatch:

permissions:
  contents: read
  id-token: write

env:
  TF_IN_AUTOMATION: "true"
  TF_INPUT: "false"

jobs:
  terraform-apply:
    name: Terraform plan and apply
    runs-on: ubuntu-latest
    environment: terraform-apply

    defaults:
      run:
        working-directory: ${{ vars.TF_WORKING_DIR }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Authenticate to Google Cloud using WIF
        uses: google-github-actions/auth@v3
        with:
          project_id: ${{ vars.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v4
        with:
          terraform_version: ${{ vars.TF_VERSION }}

      - name: Terraform fmt check
        run: terraform fmt -check -recursive

      - name: Terraform init
        run: terraform init -input=false

      - name: Terraform validate
        run: terraform validate

      - name: Terraform plan output file
        run: |
          terraform plan \
            -input=false \
            -no-color \
            -out=tfplan \
            -var="project=${{ vars.GCP_PROJECT_ID }}" \
            -var="region=${{ vars.GCP_REGION }}"

      - name: Terraform apply approved plan
        run: terraform apply -input=false -auto-approve tfplan

      - name: Terraform output
        run: terraform output
```

The apply workflow uses:

```yaml
environment: terraform-apply
```

In GitHub, I configured this environment with required approval.

So the apply step is not fully automatic.

It still requires manual approval.

## The Error I Encountered

My first plan workflow failed.

The error was:

```text
Error: Invalid value for variable

on variables.tf line 1:
variable "project" {
  var.project is ""

The project variable must not be empty.
```

The important part is:

```text
var.project is ""
```

This means Terraform did receive the variable, but the value was empty.

The workflow line was:

```bash
-var="project=${{ vars.GCP_PROJECT_ID }}"
```

So the likely issue was that `vars.GCP_PROJECT_ID` was empty or not configured correctly in GitHub Actions.

The authentication step still worked, but Terraform failed during the plan stage because the `project` variable was empty.

That was a useful lesson.

Authentication and Terraform input variables are related, but they are not the same thing.

```text
WIF authentication lets GitHub Actions access Google Cloud.
Terraform variables tell Terraform what values to use.
```

In this case, WIF was working, but my Terraform variable was not being passed correctly.

## The Fix

The fix was to check the GitHub repository variables.

In GitHub:

```text
Repository -> Settings -> Secrets and variables -> Actions -> Variables
```

I made sure this variable existed exactly:

```text
GCP_PROJECT_ID
```

with value:

```text
terraform-gcp-learning-lab
```

The variable name must match exactly.

This:

```text
GCP_PROJECT_ID
```

is not the same as:

```text
PROJECT_ID
```

or:

```text
GCP_PROJECT
```

After fixing the variable, the workflow was able to pass:

```bash
-var="project=${{ vars.GCP_PROJECT_ID }}"
```

correctly into Terraform.

## Optional Debugging Step

A safe debugging step is to print whether the variable exists without printing sensitive values.

For this lab, `GCP_PROJECT_ID` is not a secret, so printing it is acceptable.

I can add this temporarily:

```yaml
- name: Debug repository variables
  run: |
    echo "TF_WORKING_DIR=${{ vars.TF_WORKING_DIR }}"
    echo "GCP_REGION=${{ vars.GCP_REGION }}"
    echo "GCP_PROJECT_ID length=$(echo -n '${{ vars.GCP_PROJECT_ID }}' | wc -c)"
```

If the length is `0`, the variable is missing or not available to the workflow.

I would remove this debug step after the workflow is stable.

## The Successful Result

After fixing the variable, the workflow worked.

The plan workflow successfully ran:

```text
terraform fmt -check
terraform init
terraform validate
terraform plan
```

Then the manual apply workflow successfully deployed the infrastructure.

The apply workflow created:

- VPC network
- subnet

The important thing is not that the infrastructure was complex.

The important thing is that Terraform was executed through GitHub Actions using Workload Identity Federation without a service account key.

## Verifying the Infrastructure

After apply, I can verify the VPC:

```bash
gcloud compute networks list --filter="name=dev-cicd-network"
```

Expected:

```text
dev-cicd-network
```

Then verify the subnet:

```bash
gcloud compute networks subnets list \
  --filter="name=dev-cicd-subnet"
```

Expected:

```text
dev-cicd-subnet
```

I can also verify the remote state:

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/09-terraform-cicd-github-actions/
```

Expected:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/09-terraform-cicd-github-actions/default.tfstate
```

## What I Learned

This lab taught me that Terraform CI/CD is not only about running Terraform commands in GitHub Actions.

There are several separate concerns:

```text
GitHub Actions workflow
Google Cloud authentication
Workload Identity Federation
Terraform remote state
Terraform variable injection
manual approval before apply
```

The error I encountered was useful because it showed that successful Google Cloud authentication does not guarantee Terraform has received the right input values.

WIF solved the authentication problem.

GitHub repository variables solved the Terraform input problem.

The key lesson was:

```text
Authentication answers: who is running Terraform?
Variables answer: what values should Terraform use?
```

Those are different concerns.

## Next Step

This lab is not the final artifact yet.

This is the learning lab for my future Terraform CI/CD artifact.

The next step is to take this same pattern and apply it to my larger Terraform project:

```text
Production-Lite GCP Web Platform
```

That project will combine:

- Terraform modules
- remote state
- VPC and subnets
- Cloud NAT
- Managed Instance Group
- HTTP load balancer
- GitHub Actions CI/CD
- Workload Identity Federation

At that point, the infrastructure will not only be reproducible.

It will also be reviewable and safely deployable through CI/CD.

## References

- [GitHub Actions variables](https://docs.github.com/actions/learn-github-actions/variables)
- [Google GitHub Actions authentication](https://github.com/google-github-actions/auth)
- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Terraform input variables](https://developer.hashicorp.com/terraform/language/values/variables)
