# Lab 04 - Terraform tfvars and Safer Variable Values

This lab improves the previous Terraform workflow by using `terraform.tfvars`, `terraform.tfvars.example`, variable validation, and a safer GitHub pattern.

## What This Lab Creates

- Custom VPC network
- Custom subnet
- Remote Terraform state stored in Google Cloud Storage

## What This Lab Demonstrates

- Using `terraform.tfvars` to provide local variable values
- Using `terraform.tfvars.example` as a safe GitHub template
- Avoiding repeated manual variable input
- Adding validation rules to variables
- Keeping real `.tfvars` files out of version control

## Files

| File                       | Purpose                                 |
| -------------------------- | --------------------------------------- |
| `backend.tf`               | Configures the GCS remote backend       |
| `main.tf`                  | Defines the GCP resources               |
| `variables.tf`             | Declares variables and validation rules |
| `outputs.tf`               | Displays useful information after apply |
| `terraform.tfvars`         | Local real values, not committed        |
| `terraform.tfvars.example` | Safe example values, committed          |

## Setup

Copy the example variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project           = "your-gcp-project-id"
region            = "asia-southeast2"
environment       = "dev"
network_name      = "tfvars-network"
subnet_name       = "tfvars-subnet"
subnet_cidr_range = "10.30.0.0/24"
```

## Initialize

```bash
terraform init
```

## Format

```bash
terraform fmt
```

## Validate

```bash
terraform validate
```

## Plan

```bash
terraform plan
```

Terraform should automatically load values from `terraform.tfvars`.

## Apply

```bash
terraform apply
```

## Query Outputs

```bash
terraform output
terraform output lab_summary
terraform output -json
```

## Verify Remote State

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/04-tfvars-safe-variable-values/
```

## Destroy

```bash
terraform destroy
```

## Git Safety Notes

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

The real `terraform.tfvars` file may contain environment-specific or sensitive values. The example file exists so other users can recreate the expected variable structure safely.
