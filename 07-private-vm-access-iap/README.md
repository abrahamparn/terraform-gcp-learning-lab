# Lab 07 - Private VM Access with IAP, OS Login, and Service Account

This lab provisions a private Compute Engine VM on Google Cloud and accesses it through Identity-Aware Proxy (IAP) TCP forwarding.

The VM has no external IP address.

The lab uses:

- Terraform modules
- Google Cloud Storage remote state
- custom VPC and subnets
- IAP SSH firewall rule
- custom VM service account
- OS Login
- IAM bindings
- startup script verification

## What This Lab Creates

| Resource               | Description                                             |
| ---------------------- | ------------------------------------------------------- |
| Custom VPC             | Main private network                                    |
| App subnet             | Subnet where the VM is deployed                         |
| DB subnet              | Additional subnet for network structure                 |
| IAP SSH firewall rule  | Allows SSH only from IAP TCP forwarding range           |
| Internal firewall rule | Allows internal lab traffic                             |
| VM service account     | Custom identity attached to the VM                      |
| IAM binding            | Allows selected principal to use IAP TCP forwarding     |
| IAM binding            | Allows selected principal to use OS Login               |
| IAM binding            | Allows selected principal to use the VM service account |
| Compute Engine VM      | Private VM with no external IP                          |

## Folder Structure

```text
07-private-vm-access-iap/
├── backend.tf
├── main.tf
├── modules
│   ├── gcp-network
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-service-account
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── gcp-vm
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── outputs.tf
├── README.md
├── startup.sh
├── terraform.tfvars.example
└── variables.tf
```

## Architecture

```text
Root module
│
├── module.network
│   ├── VPC
│   ├── app subnet
│   ├── db subnet
│   ├── IAP SSH firewall rule
│   └── internal firewall rule
│
├── module.vm_service_account
│   └── custom service account
│
├── IAM bindings
│   ├── IAP tunnel access
│   ├── OS Login admin access
│   └── service account user access
│
└── module.vm
    └── private VM
```

## Main Learning Objective

The goal is to move from:

```text
VM exists
```

to:

```text
VM exists, has no external IP, and can be accessed securely through IAP and OS Login.
```

## Remote State

This lab uses Google Cloud Storage as the Terraform backend.

Example:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/07-private-vm-access-iap"
  }
}
```

Expected remote state path:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/07-private-vm-access-iap/default.tfstate
```

## Setup

Copy the example variable file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit:

```bash
nano terraform.tfvars
```

Set your project and admin principal:

```hcl
project = "your-gcp-project-id"
admin_principal = "user:your-email@example.com"
```

## Enable APIs

```bash
gcloud config set project YOUR_PROJECT_ID

gcloud services enable compute.googleapis.com
gcloud services enable iap.googleapis.com
gcloud services enable iam.googleapis.com
```

## Authenticate

```bash
gcloud auth login
gcloud auth application-default login
```

## Initialize

```bash
terraform init
```

Expected module initialization:

```text
Initializing modules...
- network in modules/gcp-network
- vm in modules/gcp-vm
- vm_service_account in modules/gcp-service-account
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

Expected result:

```text
Plan: 10 to add, 0 to change, 0 to destroy.
```

Expected resources:

- VPC
- app subnet
- db subnet
- IAP SSH firewall rule
- internal firewall rule
- VM service account
- IAP IAM binding
- OS Login IAM binding
- Service Account User IAM binding
- private VM

## Apply

```bash
terraform apply
```

Type:

```text
yes
```

## Outputs

```bash
terraform output
```

Useful outputs:

```bash
terraform output iap_ssh_command
terraform output vm_internal_ip
terraform output vm_service_account_email
terraform output lab_summary
```

## Verify No External IP

```bash
gcloud compute instances describe dev-iap-private-vm \
  --zone=asia-southeast2-a \
  --format="table(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs)"
```

The access config should be empty.

## SSH Through IAP

```bash
gcloud compute ssh dev-iap-private-vm \
  --zone=asia-southeast2-a \
  --tunnel-through-iap
```

## Verify Startup Script

After SSH succeeds, run inside the VM:

```bash
curl -I http://localhost
```

Expected:

```text
HTTP/1.1 200 OK
```

Check Nginx:

```bash
systemctl status nginx --no-pager
```

## Troubleshooting

Check firewall rule:

```bash
gcloud compute firewall-rules list --filter="name=dev-allow-iap-ssh"
```

Check VM tag:

```bash
gcloud compute instances describe dev-iap-private-vm \
  --zone=asia-southeast2-a \
  --format="value(tags.items)"
```

Expected:

```text
iap-ssh
```

Check IAM roles:

```bash
gcloud projects get-iam-policy YOUR_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:YOUR_EMAIL@example.com" \
  --format="table(bindings.role)"
```

Common required roles:

```text
roles/iap.tunnelResourceAccessor
roles/compute.osAdminLogin
roles/iam.serviceAccountUser
```

## Verify Remote State

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/07-private-vm-access-iap/
```

Expected:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/07-private-vm-access-iap/default.tfstate
```

## Destroy

```bash
terraform destroy
```

Type:

```text
yes
```

## Git Safety

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

## What This Lab Demonstrates

This lab demonstrates a more realistic private VM access pattern on Google Cloud.

The VM:

- has no external IP
- uses a custom service account
- has OS Login enabled
- is accessible through IAP TCP forwarding
- uses a firewall rule limited to the IAP source range
- runs a startup script that installs Nginx

The main Terraform pattern is:

```text
network module output -> root module -> VM module input
service account module output -> root module -> VM module input
IAM bindings -> controlled private VM access
```
