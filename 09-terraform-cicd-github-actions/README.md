# Lab 09 - Terraform CI/CD with GitHub Actions and Workload Identity Federation

This lab demonstrates how to run Terraform through GitHub Actions using Workload Identity Federation.

The goal is to stop running Terraform only from a local laptop and move toward a reviewable CI/CD workflow.

## Workflow

```text
Pull Request
  ↓
terraform fmt -check
  ↓
terraform init
  ↓
terraform validate
  ↓
terraform plan

Manual Apply
  ↓
terraform plan -out=tfplan
  ↓
manual GitHub environment approval
  ↓
terraform apply tfplan
```

## What This Lab Creates

This lab creates a small GCP network stack:

- custom VPC network
- two regional subnets
- remote Terraform state in Google Cloud Storage

The infrastructure is intentionally simple because the main focus is the CI/CD workflow.

## Why Workload Identity Federation

This lab does not use a downloaded service account key.

Instead, GitHub Actions authenticates to Google Cloud using Workload Identity Federation.

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

## Folder Structure

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

## Terraform Resources

This lab creates:

| Resource                             | Description        |
| ------------------------------------ | ------------------ |
| `google_compute_network.vpc_network` | Custom VPC network |
| `google_compute_subnetwork.subnets`  | Regional subnets   |

## Remote State

The backend configuration uses Google Cloud Storage.

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/09-terraform-cicd-github-actions"
  }
}
```

Expected state path:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/09-terraform-cicd-github-actions/default.tfstate
```

## GitHub Repository Variables

Add these under:

```text
Settings -> Secrets and variables -> Actions -> Variables
```

| Name                             | Example                                                                                           |
| -------------------------------- | ------------------------------------------------------------------------------------------------- |
| `GCP_PROJECT_ID`                 | `terraform-gcp-learning-lab`                                                                      |
| `GCP_REGION`                     | `asia-southeast2`                                                                                 |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/github-provider` |
| `GCP_SERVICE_ACCOUNT`            | `terraform-cicd@PROJECT_ID.iam.gserviceaccount.com`                                               |
| `TF_WORKING_DIR`                 | `09-terraform-cicd-github-actions`                                                                |
| `TF_VERSION`                     | `1.15.1`                                                                                          |

## GitHub Environment

Create an environment:

```text
terraform-apply
```

Enable required reviewers.

The apply workflow uses this environment so that Terraform apply requires manual approval.

## Workload Identity Federation Setup

Set local variables:

```bash
export PROJECT_ID="terraform-gcp-learning-lab"
export PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')"

export GITHUB_ORG="abrahamparn"
export GITHUB_REPO="terraform-gcp-learning-lab"
export REPO="${GITHUB_ORG}/${GITHUB_REPO}"

export WIF_POOL_ID="github"
export WIF_PROVIDER_ID="github-provider"
export TF_CICD_SA_ID="terraform-cicd"
export TF_CICD_SA_EMAIL="${TF_CICD_SA_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

export STATE_BUCKET="terraform-gcp-learning-lab-terraform-state"
```

Enable APIs:

```bash
gcloud config set project ${PROJECT_ID}

gcloud services enable iam.googleapis.com
gcloud services enable iamcredentials.googleapis.com
gcloud services enable sts.googleapis.com
gcloud services enable compute.googleapis.com
```

Create CI/CD service account:

```bash
gcloud iam service-accounts create ${TF_CICD_SA_ID} \
  --project=${PROJECT_ID} \
  --display-name="Terraform CI/CD Service Account"
```

Grant project permission:

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${TF_CICD_SA_EMAIL}" \
  --role="roles/compute.networkAdmin"
```

Grant state bucket permission:

```bash
gcloud storage buckets add-iam-policy-binding gs://${STATE_BUCKET} \
  --member="serviceAccount:${TF_CICD_SA_EMAIL}" \
  --role="roles/storage.admin"
```

Create Workload Identity Pool:

```bash
gcloud iam workload-identity-pools create ${WIF_POOL_ID} \
  --project=${PROJECT_ID} \
  --location="global" \
  --display-name="GitHub Actions Pool"
```

Get pool ID:

```bash
export WORKLOAD_IDENTITY_POOL_ID="$(gcloud iam workload-identity-pools describe ${WIF_POOL_ID} \
  --project=${PROJECT_ID} \
  --location="global" \
  --format="value(name)")"
```

Create provider:

```bash
gcloud iam workload-identity-pools providers create-oidc ${WIF_PROVIDER_ID} \
  --project=${PROJECT_ID} \
  --location="global" \
  --workload-identity-pool=${WIF_POOL_ID} \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository == '${REPO}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"
```

Allow GitHub repository to impersonate service account:

```bash
gcloud iam service-accounts add-iam-policy-binding ${TF_CICD_SA_EMAIL} \
  --project=${PROJECT_ID} \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/${REPO}"
```

Get provider name:

```bash
export WORKLOAD_IDENTITY_PROVIDER="$(gcloud iam workload-identity-pools providers describe ${WIF_PROVIDER_ID} \
  --project=${PROJECT_ID} \
  --location="global" \
  --workload-identity-pool=${WIF_POOL_ID} \
  --format="value(name)")"

echo ${WORKLOAD_IDENTITY_PROVIDER}
```

Use the output as the `GCP_WORKLOAD_IDENTITY_PROVIDER` GitHub repository variable.

## Plan Workflow

The plan workflow runs on pull requests.

It executes:

```text
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

## Apply Workflow

The apply workflow runs manually through `workflow_dispatch`.

It executes:

```text
terraform plan -out=tfplan
terraform apply tfplan
```

The apply job uses the `terraform-apply` GitHub environment so approval can be required before applying changes.

## Local Test

Optional local test:

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform plan \
  -var="project=terraform-gcp-learning-lab" \
  -var="region=asia-southeast2"
```

Expected plan:

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

## Verify Resources

Check VPC:

```bash
gcloud compute networks list --filter="name=dev-cicd-network"
```

Check subnet:

```bash
gcloud compute networks subnets list \
  --filter="name~dev-.*-subnet"
```

Check remote state:

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/09-terraform-cicd-github-actions/
```

## Cleanup

Destroy locally:

```bash
terraform destroy \
  -var="project=terraform-gcp-learning-lab" \
  -var="region=asia-southeast2"
```

## What This Lab Demonstrates

This lab demonstrates:

- Terraform execution through GitHub Actions
- pull request planning
- manual apply
- Workload Identity Federation
- no service account key
- remote state access from CI/CD
- basic separation between review and execution

The main lesson:

```text
Terraform CI/CD is not just automation.
It is change control for infrastructure.
```
