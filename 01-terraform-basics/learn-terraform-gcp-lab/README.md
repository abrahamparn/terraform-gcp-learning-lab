# Lab 01 - First GCP VPC with Terraform

This lab provisions a simple Google Cloud VPC network using Terraform.

The goal is to understand the basic Terraform workflow:

1. Write configuration
2. Authenticate to Google Cloud
3. Initialize Terraform
4. Format and validate configuration
5. Review the execution plan
6. Apply the configuration
7. Inspect state
8. Destroy the infrastructure

## Prerequisites

- Terraform CLI installed
- Google Cloud CLI installed
- Google Cloud project with billing enabled
- Compute Engine API enabled

## Configure Google Cloud Project

```bash
gcloud config set project [YOUR_PROJECT_ID]
gcloud services enable compute.googleapis.com
```

## Authenticate

```bash
gcloud auth application-default login
```

## Initialize Terraform

```bash
terraform init
```

## Format Configuration

```bash
terraform fmt
```

## Validate Configuration

```bash
terraform validate
```

## Review Plan

```bash
terraform plan
```

## Apply Configuration

```bash
terraform apply
```

Type:

```text
yes
```

## Inspect State

```bash
terraform show
terraform state list
```

## Destroy Infrastructure

```bash
terraform destroy
```

type:

```text
Yes
```
