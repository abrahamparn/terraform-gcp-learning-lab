# Lab 05 - Reusable GCP Network Module

This lab introduces Terraform modules by turning a GCP VPC, subnets and firewall rules into a reusable local module.

## What This Lab Creates

- Custom VPC network
- Multiple subnets using `for_each`
- Optional ingress firewall rules using `for_each`
- Dynamic firewall `allow` blocks
- Module outputs
- Remote state using Google Cloud Storage

## Folder Structure

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

## Setup

Copy the example variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project      = "your-gcp-project-id"
region       = "asia-southeast2"
environment  = "dev"
network_name = "network-module"
```

## Initialize

```bash
terraform init
```

## Format

```bash
terraform fmt -recursive
```

## Validate

```bash
terraform validate
```

## Plan

```bash
terraform plan
```

Expected resources:

- 1 VPC network
- 2 subnets
- 2 firewall rules

## Apply

```bash
terraform apply
```

## Query Outputs

```bash
terraform output
terraform output lab_summary
terraform output subnets
terraform output -json
```

## Verify in Google Cloud

```bash
gcloud compute networks list --filter="name=dev-network-module"

gcloud compute networks subnets list \
  --filter="network:dev-network-module"

gcloud compute firewall-rules list \
  --filter="network:dev-network-module"
```

## Verify Remote State

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/05-gcp-network-module/
```

## Destroy

```bash
terraform destroy
```

## Notes

This lab uses a local child module located at:

```text
modules/gcp-network
```

The root module calls the child module using:

```hcl
module "network" {
  source = "./modules/gcp-network"
}
```

The child module is responsible for creating the network resources. The root module is responsible for provider configuration, backend configuration, input values, and consuming module outputs.
