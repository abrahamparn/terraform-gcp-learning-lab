# Lab 08 - Managed Instance Group, Cloud NAT, Service Account, and HTTP Load Balancer

This lab provisions a production-like HTTP serving pattern on Google Cloud using Terraform.

The main goal is to move from a single private VM into a more realistic architecture:

```text
private backend instances
+ Managed Instance Group
+ Cloud NAT
+ HTTP health check
+ backend service
+ external HTTP load balancer
```

This lab also adds a dedicated service account for the MIG instances, so the backend VMs do not rely on the default Compute Engine service account.

## What This Lab Creates

| Component                          | Description                                              |
| ---------------------------------- | -------------------------------------------------------- |
| Custom VPC                         | Main network boundary                                    |
| App subnet                         | Subnet for MIG backend instances                         |
| DB subnet                          | Additional subnet for network structure                  |
| Cloud Router                       | Required by Cloud NAT                                    |
| Cloud NAT                          | Outbound internet for private backend instances          |
| Service account                    | Custom identity attached to MIG instances                |
| IAP IAM binding                    | Allows IAP tunnel access for the admin principal         |
| OS Login IAM binding               | Allows OS Login admin access                             |
| Service Account User IAM binding   | Allows the admin principal to use the VM service account |
| Firewall rule for LB/health checks | Allows Google load balancer and health check traffic     |
| Internal firewall rule             | Allows internal traffic between lab subnets              |
| HTTP health check                  | Checks backend instance health                           |
| Instance template                  | Defines how backend VMs are created                      |
| Regional MIG                       | Runs multiple backend instances                          |
| Global IP address                  | Public entry point for HTTP load balancer                |
| Backend service                    | Connects the load balancer to the MIG                    |
| URL map                            | Routes HTTP traffic                                      |
| Target HTTP proxy                  | HTTP proxy for the load balancer                         |
| Global forwarding rule             | Receives external HTTP traffic                           |

## Architecture

```text
Client
  ↓
Global forwarding rule
  ↓
Target HTTP proxy
  ↓
URL map
  ↓
Backend service
  ↓
Regional Managed Instance Group
  ↓
Private backend VMs
  ↓ outbound only
Cloud NAT
  ↓
Internet package repositories
```

## Why Cloud NAT Is Included

The backend VM instances do not have external IP addresses.

Without Cloud NAT, the startup script may fail when it tries to run:

```bash
apt-get update -y
apt-get install -y nginx
```

Cloud NAT gives the private backend VMs outbound internet access without exposing them directly to inbound internet traffic.

This fixes the issue from the previous private VM lab, where the VM had no external IP and therefore failed to fetch packages from Debian repositories.

## Why a Service Account Is Included

This lab also creates a dedicated service account for the MIG instances.

Instead of using the default Compute Engine service account, the backend VMs use a custom service account created by Terraform.

This is a better habit because each workload should have a clear identity.

## Folder Structure

```text
08-mig-nat-http-lb/
├── backend.tf
├── main.tf
├── outputs.tf
├── startup.sh
├── terraform.tfvars
├── variables.tf
├── modules/
│   ├── gcp-cloud-nat/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-http-lb/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-mig/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── gcp-network/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── gcp-service-account/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
```

## Modules

This lab uses five local modules:

| Module                | Purpose                                       |
| --------------------- | --------------------------------------------- |
| `gcp-network`         | Creates VPC, subnets, and firewall rules      |
| `gcp-cloud-nat`       | Creates Cloud Router and Cloud NAT            |
| `gcp-service-account` | Creates a custom service account              |
| `gcp-mig`             | Creates instance template and regional MIG    |
| `gcp-http-lb`         | Creates external HTTP load balancer resources |

## Remote State

This lab uses Google Cloud Storage as the Terraform backend.

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/08-mig-http-load-balancer"
  }
}
```

Expected remote state path:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/08-mig-http-load-balancer/default.tfstate
```

## Root Module Flow

The root module wires all child modules together.

```text
module.network
    ↓ network self-link
module.cloud_nat

module.network
    ↓ app subnet self-link
module.mig

module.service_account
    ↓ service account email
module.mig

module.mig
    ↓ instance group URL
module.http_lb
```

The key pattern is:

```text
network module output -> MIG module input
service account module output -> MIG module input
MIG module output -> load balancer module input
```

## Setup

Copy the example tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit:

```bash
nano terraform.tfvars
```

Set your project and admin principal:

```hcl
project         = "your-gcp-project-id"
admin_principal = "user:your-email@example.com"
```

## Example Variables

```hcl
project         = "your-gcp-project-id"
region          = "asia-southeast2"
environment     = "dev"
admin_principal = "user:your-email@example.com"

network_name = "mig-lb-network"

subnets = {
  app = {
    cidr_range = "10.80.1.0/24"
  }

  db = {
    cidr_range = "10.80.2.0/24"
  }
}

firewall_rules = {
  allow-lb-health-check = {
    description   = "Allow Google Cloud load balancer health checks and proxy traffic."
    source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
    target_tags   = ["web-backend"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["80"]
      }
    ]
  }

  allow-internal = {
    description   = "Allow internal traffic between lab subnets."
    source_ranges = ["10.80.0.0/16"]

    allow = [
      {
        protocol = "tcp"
        ports    = ["0-65535"]
      },
      {
        protocol = "udp"
        ports    = ["0-65535"]
      },
      {
        protocol = "icmp"
      }
    ]
  }
}

mig_name           = "web-mig"
mig_instance_count = 2
mig_machine_type   = "e2-micro"
mig_zone           = "asia-southeast2-a"
mig_subnet_key     = "app"
mig_tags           = ["web-backend"]

mig_service_account_id           = "web-mig-sa"
mig_service_account_display_name = "Web MIG Service Account"

lb_name  = "web-lb"
app_port = 80
```

## Enable APIs

```bash
gcloud config set project YOUR_PROJECT_ID

gcloud services enable compute.googleapis.com
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
- cloud_nat in modules/gcp-cloud-nat
- http_lb in modules/gcp-http-lb
- mig in modules/gcp-mig
- network in modules/gcp-network
- service_account in modules/gcp-service-account
```

## Format

Because this lab contains nested modules:

```bash
terraform fmt -recursive
```

## Validate

```bash
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

## Plan

```bash
terraform plan
```

Expected resource categories:

- VPC network
- app subnet
- db subnet
- Cloud Router
- Cloud NAT
- service account
- IAM bindings
- firewall rule for load balancer and health checks
- internal firewall rule
- HTTP health check
- instance template
- regional managed instance group
- global IP address
- backend service
- URL map
- target HTTP proxy
- global forwarding rule

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
terraform output load_balancer_ip
terraform output load_balancer_url
terraform output curl_test_command
terraform output lab_summary
```

## Test the Load Balancer

```bash
curl -i $(terraform output -raw load_balancer_url)
```

Expected:

```text
HTTP/1.1 200 OK
```

The response body should include:

```text
Hello from Terraform Lab 008
```

## Test Load Balancing

Run the request multiple times:

```bash
for i in {1..5}; do
  curl -s $(terraform output -raw load_balancer_url) | grep Hostname
done
```

If both backend instances are healthy and receiving traffic, the hostname may change across requests.

## Verify MIG

```bash
gcloud compute instance-groups managed list \
  --filter="name=dev-web-mig"
```

List MIG instances:

```bash
gcloud compute instance-groups managed list-instances dev-web-mig \
  --region=asia-southeast2
```

## Verify Backend Health

```bash
gcloud compute backend-services get-health dev-web-lb-backend \
  --global
```

Expected:

```text
HEALTHY
```

If the backend is unhealthy, wait a few minutes and check again.

Common causes:

- startup script is still running
- Nginx failed to install
- health check firewall rule is missing
- health check source ranges are wrong
- named port mismatch
- backend instances are not listening on port 80

## Verify Backend VMs Have No External IP

```bash
gcloud compute instances list \
  --filter="name~dev-web-mig"
```

The external IP column should be empty.

That means backend instances are private.

## Verify Cloud NAT

```bash
gcloud compute routers nats list \
  --router=dev-nat-router \
  --region=asia-southeast2
```

Expected:

```text
dev-nat-gateway
```

## Verify Remote State

```bash
gcloud storage ls gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/08-mig-http-load-balancer/
```

Expected:

```text
gs://terraform-gcp-learning-lab-terraform-state/terraform-gcp-learning-lab/08-mig-http-load-balancer/default.tfstate
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

This lab demonstrates a production-like serving pattern:

```text
private backend instances
+ Cloud NAT for outbound internet
+ Managed Instance Group
+ HTTP health checks
+ external HTTP load balancer
+ custom service account
```

The backend VMs remain private.

Cloud NAT provides outbound internet access for package installation.

The HTTP load balancer becomes the public entry point.
