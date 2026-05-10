# Private VM Access with IAP, OS Login, and Service Account

In the previous Terraform lab, I created a private Compute Engine VM using module composition.

The VM was created from a reusable `gcp-vm` module, while the network was created from a reusable `gcp-network` module.

That lab helped me understand this pattern:

```text
network module output -> root module -> VM module input
```

For this lab, I wanted to improve the access pattern.

Previously, the VM already had:

- no external IP
- an IAP SSH firewall rule
- the `iap-ssh` network tag

However, that was only half of the private access story.

In this lab, I wanted to make the private VM access pattern more complete by adding:

- custom VM service account
- OS Login
- IAP TCP forwarding access
- IAM bindings
- startup script verification
- SSH access through IAP

The goal was to move from:

```text
VM exists
```

to:

```text
VM exists, has no external IP, and can be accessed in a controlled way through IAP.
```

## What This Lab Builds

This lab provisions:

- custom VPC network
- app subnet
- db subnet
- firewall rule for IAP SSH
- internal firewall rule
- custom VM service account
- IAM binding for IAP TCP forwarding
- IAM binding for OS Login
- IAM binding for service account usage
- private Compute Engine VM
- startup script for Nginx installation
- remote Terraform state in Google Cloud Storage

The important thing is that the VM has **no external IP address**.

## Architecture

The structure is now composed of three child modules:

```text
07-private-vm-access-iap/
├── modules/
│   ├── gcp-network/
│   ├── gcp-service-account/
│   └── gcp-vm/
```

The root module wires them together:

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
│   └── custom VM service account
│
├── IAM bindings
│   ├── IAP tunnel access
│   ├── OS Login admin access
│   └── service account user access
│
└── module.vm
    └── private VM
```

The main Terraform pattern is:

```text
network module output -> root module -> VM module input
service account module output -> root module -> VM module input
IAM bindings -> controlled private VM access
```

## Why IAP?

Normally, if a VM has an external IP, I can SSH into it from the internet if the firewall allows it.

But exposing SSH publicly is not a good habit.

For this lab, I wanted the VM to stay private.

So instead of giving the VM an external IP, I used Identity-Aware Proxy TCP forwarding.

The firewall rule allows SSH only from Google’s IAP TCP forwarding source range:

```text
35.235.240.0/20
```

The VM also has this network tag:

```text
iap-ssh
```

So the firewall rule applies only to instances with that tag.

## Why OS Login?

I also enabled OS Login.

Instead of managing SSH keys manually in project or instance metadata, OS Login allows VM login access to be controlled through IAM.

For this lab, the selected admin principal receives:

```text
roles/compute.osAdminLogin
```

This allows the principal to log in through OS Login with admin-level access.

## Why a Custom Service Account?

I also created a dedicated service account for the VM.

The service account is:

```text
dev-iap-private-vm-sa@terraform-gcp-learning-lab.iam.gserviceaccount.com
```

This is better than blindly using the default Compute Engine service account.

In real environments, each workload should have an identity that matches what it needs to do.

For this lab, the service account exists mainly to practice a cleaner VM identity pattern.

## Backend Configuration

This lab still uses remote state in Google Cloud Storage.

Example `backend.tf`:

```hcl
terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/07-private-vm-access-iap"
  }
}
```

This means the state for this lab is isolated from the previous labs.

## Root Module

The root module calls three child modules:

```hcl
module "network" {
  source = "./modules/gcp-network"

  environment    = var.environment
  region         = var.region
  network_name   = var.network_name
  subnets        = var.subnets
  firewall_rules = var.firewall_rules
}

module "vm_service_account" {
  source = "./modules/gcp-service-account"

  account_id   = "${var.environment}-${var.vm_service_account_id}"
  display_name = "${var.environment} ${var.vm_service_account_display_name}"
}

module "vm" {
  source = "./modules/gcp-vm"

  environment           = var.environment
  vm_name               = var.vm_name
  machine_type          = var.vm_machine_type
  zone                  = var.vm_zone
  tags                  = var.vm_tags
  subnetwork_self_link  = module.network.subnets[var.vm_subnet_key].self_link
  service_account_email = module.vm_service_account.email
  startup_script_path   = "${path.module}/startup.sh"
  enable_oslogin        = var.enable_oslogin
}
```

The important lines are:

```hcl
subnetwork_self_link = module.network.subnets[var.vm_subnet_key].self_link
service_account_email = module.vm_service_account.email
```

This means the VM module does not create its own network or service account.

Instead, it consumes outputs from other modules.

## IAM Bindings

This lab also creates IAM bindings.

```hcl
resource "google_project_iam_member" "iap_tunnel_user" {
  project = var.project
  role    = "roles/iap.tunnelResourceAccessor"
  member  = var.admin_principal
}

resource "google_project_iam_member" "os_admin_login" {
  project = var.project
  role    = "roles/compute.osAdminLogin"
  member  = var.admin_principal
}

resource "google_service_account_iam_member" "vm_service_account_user" {
  service_account_id = module.vm_service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = var.admin_principal
}
```

These roles support the access pattern:

| Role                               | Purpose                                            |
| ---------------------------------- | -------------------------------------------------- |
| `roles/iap.tunnelResourceAccessor` | Allows IAP TCP forwarding                          |
| `roles/compute.osAdminLogin`       | Allows OS Login with admin privileges              |
| `roles/iam.serviceAccountUser`     | Allows the principal to use the VM service account |

## Network Module

The network module creates:

- VPC
- subnets
- firewall rules

The firewall rule for IAP SSH allows traffic from:

```text
35.235.240.0/20
```

and targets instances tagged with:

```text
iap-ssh
```

My Terraform output showed:

```text
"allow-iap-ssh" = {
  "name" = "dev-allow-iap-ssh"
  "source_ranges" = toset([
    "35.235.240.0/20",
  ])
  "target_tags" = toset([
    "iap-ssh",
  ])
}
```

## VM Module

The VM module creates the private Compute Engine instance.

The VM resource uses:

```hcl
network_interface {
  subnetwork = var.subnetwork_self_link
}
```

There is no `access_config` block.

That means the VM does not receive an external IP address.

The VM also uses:

```hcl
metadata = {
  enable-oslogin = tostring(var.enable_oslogin)
}
```

and attaches the custom service account:

```hcl
service_account {
  email  = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}
```

## Terraform Apply Result

After running:

```bash
terraform apply
```

the lab completed successfully.

The output showed:

```text
vm_name = "dev-iap-private-vm"
vm_internal_ip = "10.60.1.2"
vm_machine_type = "e2-micro"
vm_service_account_email = "dev-iap-private-vm-sa@terraform-gcp-learning-lab.iam.gserviceaccount.com"
vm_zone = "asia-southeast2-a"
```

The lab summary showed:

```text
lab_summary = {
  "environment" = "dev"
  "firewall_count" = 2
  "iap_ssh_enabled_pattern" = true
  "network_name" = "dev-iap-private-network"
  "os_login_enabled" = true
  "project" = "terraform-gcp-learning-lab"
  "region" = "asia-southeast2"
  "subnet_count" = 2
  "vm_external_ip" = "none"
  "vm_internal_ip" = "10.60.1.2"
  "vm_name" = "dev-iap-private-vm"
  "vm_service_account_email" = "dev-iap-private-vm-sa@terraform-gcp-learning-lab.iam.gserviceaccount.com"
  "vm_subnet_key" = "app"
  "vm_zone" = "asia-southeast2-a"
}
```

This confirmed that the VM was created privately with:

```text
vm_external_ip = "none"
```

## Verifying That the VM Has No External IP

I verified the VM using:

```bash
gcloud compute instances describe dev-iap-private-vm \
  --zone=asia-southeast2-a \
  --format="table(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs)"
```

The result was:

```text
NAME                NETWORK_IP  ACCESS_CONFIGS
dev-iap-private-vm  10.60.1.2
```

The `ACCESS_CONFIGS` field is empty.

That confirms that the VM has no external IP address.

## SSH Command Through IAP

Terraform also generated the IAP SSH command:

```text
gcloud compute ssh dev-iap-private-vm --zone=asia-southeast2-a --tunnel-through-iap
```

This command is important because the VM is private.

Without an external IP, I cannot SSH directly from the public internet.

The intended access path is through IAP TCP forwarding.

## The One Thing That Failed: Startup Script Internet Access

Almost everything worked.

But one thing failed.

The startup script tried to install Nginx:

```bash
apt-get update -y
apt-get install -y nginx
```

The VM failed to fetch the Nginx package from Debian repositories.

The error was:

```text
Failed to fetch https://deb.debian.org/debian-security/pool/updates/main/n/nginx/nginx_1.22.1-9%2bdeb12u4_amd64.deb
Cannot initiate the connection to deb.debian.org:443
Network is unreachable
```

This happened because the VM has no external IP address and I did not configure Cloud NAT.

So the VM was private, but it also had no outbound internet path to reach Debian package repositories.

This is an important distinction.

```text
IAP solves private administrative access into the VM.
Cloud NAT solves outbound internet access from the VM.
```

In this lab, I configured IAP access, but I did not configure Cloud NAT yet.

That means SSH through IAP can work, but installing packages from the internet during startup may fail.

This is not a Terraform failure.

This is a network design gap.

## What Worked

The successful parts were:

- custom VPC created
- app and db subnets created
- VM created in the app subnet
- VM has no external IP
- custom service account attached to the VM
- OS Login enabled
- IAP SSH firewall rule created
- IAP SSH command generated
- Terraform outputs confirmed the infrastructure
- remote state continued to work

The key output was:

```text
vm_external_ip = "none"
vm_internal_ip = "10.60.1.2"
iap_ssh_enabled_pattern = true
os_login_enabled = true
```

That means the core private access pattern was successfully provisioned.

## What Did Not Work

The startup script verification did not fully work because the VM could not install Nginx.

The command that would normally verify Nginx was:

```bash
curl -I http://localhost
```

But since Nginx installation failed, this verification could not succeed yet.

The root cause was not the startup script itself.

The root cause was that the private VM had no outbound internet path.

## How I Would Fix This Next

There are several ways to fix this.

The most appropriate next lab is to add:

- Cloud Router
- Cloud NAT
- private VM outbound internet access
- startup script retry
- Nginx installation verification

That would allow the VM to stay private while still being able to reach package repositories on the internet.

The improved design would be:

```text
Private VM
    ↓ outbound internet
Cloud NAT
    ↓
Internet package repositories
```

The VM would still have no external IP.

But it could access the internet for outbound traffic through Cloud NAT.

## What I Learned

This lab clarified an important distinction:

```text
Private inbound access and private outbound access are different problems.
```

IAP helps solve inbound administrative access.

It lets me access a private VM without giving it an external IP.

But IAP does not automatically give the VM outbound internet access.

For outbound internet access from a VM with no external IP, I need something like Cloud NAT.

This is an important infrastructure lesson.

At first, I thought:

```text
The VM has IAP, so it should be fine.
```

But that was incomplete.

The better understanding is:

```text
IAP = controlled inbound access to private VM
Cloud NAT = outbound internet access from private VM
```

This failure actually made the lab better because it revealed a real production design consideration.
