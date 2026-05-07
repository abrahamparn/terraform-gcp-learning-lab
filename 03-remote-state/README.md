# Lab 05 - Terraform Remote State on Google Cloud Storage

This lab demonstrates how to store Terraform state remotely using the Google Cloud Storage backend.

## What This Lab Creates

- Custom VPC network
- Custom subnet
- Terraform state stored in a GCS bucket

## Why Remote State Matters

By default, Terraform stores state locally in `terraform.tfstate`.

Local state is acceptable for beginner labs, but it is not ideal for collaboration or production workflows.

Remote state allows Terraform state to be stored in a shared backend, such as Google Cloud Storage.

## Prerequisites

- Terraform CLI installed
- Google Cloud CLI installed
- Google Cloud project with billing enabled
- Compute Engine API enabled
- Cloud Storage API enabled
- GCS bucket created for Terraform state

## Create the State Bucket

```bash
export PROJECT_ID="YOUR_PROJECT_ID"
export STATE_BUCKET="${PROJECT_ID}-terraform-state"
export REGION="asia-southeast2"

gcloud config set project ${PROJECT_ID}

gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com

gcloud storage buckets create gs://${STATE_BUCKET} \
  --project=${PROJECT_ID} \
  --location=${REGION} \
  --uniform-bucket-level-access

gcloud storage buckets update gs://${STATE_BUCKET} \
  --versioning
```

## Configure Backend

Update `backend.tf` with your bucket name:

```hcl
terraform {
  backend "gcs" {
    bucket = "YOUR_PROJECT_ID-terraform-state"
    prefix = "terraform-gcp-learning-lab/05-remote-state-gcs"
  }
}
```

## Initialize Terraform

```bash
terraform init
```

## Format and Validate

```bash
terraform fmt
terraform validate
```

## Plan

```bash
terraform plan
```

## Apply

```bash
terraform apply
```

## Verify Remote State

```bash
gcloud storage ls gs://${STATE_BUCKET}/terraform-gcp-learning-lab/05-remote-state-gcs/
```

## Query Outputs

```bash
terraform output
```

## Destroy Infrastructure

```bash
terraform destroy
```

## Notes

The GCS bucket is created outside this Terraform configuration because Terraform needs the backend bucket to exist before it can store state in it.

This lab intentionally keeps the infrastructure simple so the focus remains on remote state.
