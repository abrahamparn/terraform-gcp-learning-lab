Hi, we are back again. Previously, I created a simple Google Cloud VPC and then improved the configuration by introducing variables.

This time, I want to continue with another Terraform concept: **outputs**. But, we will not be using the previous code, because adding outputs for one vpc is too simple. So, I made the lab slightly more practical.

In this lab, I will create:

- a custom VPC network
- a subnet with a defined CIDR range
- a small Compute Engine VM
- Terraform outputs to query useful information after provisioning

The goal is to understand how Terraform outputs can expose important infrastructure data after resources are created.

Reference: [Hasicorp website about gcp tutorial](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-outputs)

## Why Outputs Matter

When Terraform creates infrastructure, it stores a lot of resource data in the state file. However, as users, we usually do not need to read everything.

Most of the time, we only care about specific values, such as:

- the VM internal IP address
- the VPC name
- the subnet CIDR range
- the VM self-link
- a structured summary of the created resources

This is where outputs are useful.

Outputs allow us to expose selected resource information after `terraform apply`.

They can also be queried later using:

```bash
terraform output
```

## What This Lab Builds

This lab creates three Google Cloud resources:

| Resource                              | Purpose                                   |
| ------------------------------------- | ----------------------------------------- |
| `google_compute_network.vpc_network`  | Custom VPC network                        |
| `google_compute_subnetwork.subnet`    | Regional subnet inside the VPC            |
| `google_compute_instance.vm_instance` | Small Compute Engine VM inside the subnet |

The VM will be created without an external public IP address.

This happens because the `network_interface` block does not include an `access_config` block.

For this lab, that is fine because the goal is not to SSH into the VM or expose an application. The goal is to learn how Terraform outputs work.

## Create a new lab folder

Because this is a new lab, I created a new folder.

````bash
mkdir learn-terraform-gcp-lab-output
cd learn-terraform-gcp-lab-output
```Then create three files:

```bash
touch main.tf variables.tf outputs.tf
````

The folder should look like this:

```text
learn-terraform-gcp-lab-output/
├── main.tf
├── variables.tf
└── outputs.tf
```

## Create `variables.tf`

First, open `variables.tf`.

```bash
nano variables.tf
```

Then add the following variable declarations:

```hcl
variable "project" {
  description = "The Google Cloud project ID where resources will be created."
  type        = string
}

variable "region" {
  description = "The Google Cloud region where regional resources will be created."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The Google Cloud zone where the VM instance will be created."
  type        = string
  default     = "us-central1-c"
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "terraform-output-network"
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "terraform-output-subnet"
}

variable "subnet_cidr_range" {
  description = "The CIDR range for the subnet."
  type        = string
  default     = "10.10.0.0/24"
}

variable "instance_name" {
  description = "The name of the Compute Engine VM instance."
  type        = string
  default     = "terraform-output-vm"
}

variable "machine_type" {
  description = "The machine type for the Compute Engine VM instance."
  type        = string
  default     = "e2-micro"
}
```

This file only declares the input variables Terraform can accept.

The important distinction is:

```text
variables.tf declares input variables.
main.tf uses those variables.
outputs.tf exposes selected resource data after apply.
```

## Create `main.tf`

Next, open `main.tf`.

```bash
nano main.tf
```

Then add the following Terraform configuration:

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
  zone    = var.zone
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

resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }
}
```

### Understanding `main.tf`

#### Google Provider

The provider block tells Terraform which Google Cloud project, region, and zone to use.

```hcl
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}
```

The values come from the variables declared in `variables.tf`.

#### Custom VPC Network

```hcl
resource "google_compute_network" "vpc_network" {
  name                    = var.network_name
  auto_create_subnetworks = false
}
```

This creates a custom VPC network.

The important part is:

```hcl
auto_create_subnetworks = false
```

This means Google Cloud will not automatically create subnets for us.

Instead, we will define our own subnet manually.

---

#### Subnet

```hcl
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = var.subnet_cidr_range
}
```

This creates a subnet inside the VPC.

The subnet uses this CIDR range:

```text
10.10.0.0/24
```

This value comes from:

```hcl
var.subnet_cidr_range
```

#### Compute Engine VM

```hcl
resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
  }
}
```

This creates a small Compute Engine VM using:

```text
e2-micro
```

The VM is attached to the subnet using:

```hcl
subnetwork = google_compute_subnetwork.subnet.id
```

Because there is no `access_config` block, this VM does not get an external public IP address.

It only receives an internal IP address from the subnet.

## Create `outputs.tf`

Now we create the output definitions.

Open `outputs.tf`.

```bash
nano outputs.tf
```

Then add:

```hcl
output "vpc_network_name" {
  description = "The name of the VPC network created by Terraform."
  value       = google_compute_network.vpc_network.name
}

output "vpc_network_id" {
  description = "The ID of the VPC network created by Terraform."
  value       = google_compute_network.vpc_network.id
}

output "subnet_name" {
  description = "The name of the subnet created by Terraform."
  value       = google_compute_subnetwork.subnet.name
}

output "subnet_cidr_range" {
  description = "The CIDR range of the subnet created by Terraform."
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "vm_instance_name" {
  description = "The name of the VM instance created by Terraform."
  value       = google_compute_instance.vm_instance.name
}

output "vm_instance_zone" {
  description = "The zone where the VM instance was created."
  value       = google_compute_instance.vm_instance.zone
}

output "vm_internal_ip" {
  description = "The internal IP address of the VM instance."
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}

output "vm_self_link" {
  description = "The self-link of the VM instance."
  value       = google_compute_instance.vm_instance.self_link
}

output "lab_summary" {
  description = "A structured summary of the resources created in this lab."

  value = {
    project        = var.project
    region         = var.region
    zone           = var.zone
    vpc_name       = google_compute_network.vpc_network.name
    subnet_name    = google_compute_subnetwork.subnet.name
    subnet_cidr    = google_compute_subnetwork.subnet.ip_cidr_range
    vm_name        = google_compute_instance.vm_instance.name
    vm_internal_ip = google_compute_instance.vm_instance.network_interface[0].network_ip
  }
}
```

This is the main focus of the lab.

Instead of only creating resources, we are selecting which resource attributes should be easy to view after provisioning.

## Format the Terraform Files

Run:

```bash
terraform fmt
```

This formats the Terraform configuration files.

Initialize Terraform

Run:

```bash
terraform init
```

This initializes the working directory and downloads the Google provider.

## Validate the Configuration

Run:

```bash
terraform validate
```

Expected output:

```bash
Success! The configuration is valid.
```

## Apply the Configuration

Run:

```bash
terraform apply
```

Because the `project` variable does not have a default value, Terraform will ask for it.

```bash
var.project
  The Google Cloud project ID where resources will be created.

  Enter a value:
```

Enter your Google Cloud project ID.

Terraform will show the execution plan.

In my case, Terraform planned to create three resources:

```text
Plan: 3 to add, 0 to change, 0 to destroy.
```

The resources were:

```text
google_compute_network.vpc_network
google_compute_subnetwork.subnet
google_compute_instance.vm_instance
```

Terraform also showed that some output values were only known after apply:

```text
vm_internal_ip = (known after apply)
vm_self_link   = (known after apply)
```

That makes sense because the VM internal IP and self-link do not exist until Google Cloud creates the VM.

After reviewing the plan, type:

```bash
yes
```

## Apply Result

After Terraform finished provisioning, my output looked like this:

```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

Outputs:

lab_summary = {
  "project" = "terraform-gcp-learning-lab"
  "region" = "us-central1"
  "subnet_cidr" = "10.10.0.0/24"
  "subnet_name" = "terraform-output-subnet"
  "vm_internal_ip" = "10.10.0.2"
  "vm_name" = "terraform-output-vm"
  "vpc_name" = "terraform-output-network"
  "zone" = "us-central1-c"
}
subnet_cidr_range = "10.10.0.0/24"
subnet_name = "terraform-output-subnet"
vm_instance_name = "terraform-output-vm"
vm_instance_zone = "us-central1-c"
vm_internal_ip = "10.10.0.2"
vpc_network_id = "projects/terraform-gcp-learning-lab/global/networks/terraform-output-network"
vpc_network_name = "terraform-output-network"
```

At this point, Terraform had created:

- one VPC network
- one subnet
- one VM instance

It also exposed selected infrastructure data through outputs.

## Query the Outputs

After apply, we can query all outputs using:

```bash
terraform output
```

Example output:

```text
lab_summary = {
  "project" = "terraform-gcp-learning-lab"
  "region" = "us-central1"
  "subnet_cidr" = "10.10.0.0/24"
  "subnet_name" = "terraform-output-subnet"
  "vm_internal_ip" = "10.10.0.2"
  "vm_name" = "terraform-output-vm"
  "vpc_name" = "terraform-output-network"
  "zone" = "us-central1-c"
}
subnet_cidr_range = "10.10.0.0/24"
subnet_name = "terraform-output-subnet"
vm_instance_name = "terraform-output-vm"
vm_instance_zone = "us-central1-c"
vm_internal_ip = "10.10.0.2"
vpc_network_id = "projects/terraform-gcp-learning-lab/global/networks/terraform-output-network"
vpc_network_name = "terraform-output-network"
```

We can also query one specific output.

For example:

```bash
terraform output vm_internal_ip
```

The result:

```text
"10.10.0.2"
```

This is useful because I do not need to inspect the full Terraform state just to find the VM internal IP address.

## Query a Structured Output

I also created a structured output called `lab_summary`.

Run:

```bash
terraform output lab_summary
```

Example result:

```text
{
  "project" = "terraform-gcp-learning-lab"
  "region" = "us-central1"
  "subnet_cidr" = "10.10.0.0/24"
  "subnet_name" = "terraform-output-subnet"
  "vm_internal_ip" = "10.10.0.2"
  "vm_name" = "terraform-output-vm"
  "vpc_name" = "terraform-output-network"
  "zone" = "us-central1-c"
}
```

This is more readable than scanning the full state file.

## Output as JSON

Terraform can also return outputs in JSON format.

Run:

```bash
terraform output -json
```

This returns structured JSON data.

Example:

```json
{
  "vm_internal_ip": {
    "sensitive": false,
    "type": "string",
    "value": "10.10.0.2"
  },
  "vpc_network_name": {
    "sensitive": false,
    "type": "string",
    "value": "terraform-output-network"
  }
}
```

We can also save the output into a JSON file:

```bash
terraform output -json > terraform-outputs.json
```

This can be useful when another script, pipeline, or tool needs to consume Terraform output data.

## Inspect Terraform State

Outputs are useful, but they do not replace state.

Terraform still stores resource information in the state file.

To list resources tracked by Terraform, run:

```bash
terraform state list
```

My result:

```text
google_compute_instance.vm_instance
google_compute_network.vpc_network
google_compute_subnetwork.subnet
```

Then I tried to inspect the Compute Engine instance with:

```bash
terraform state show google_compute_instance
```

Terraform returned an error:

```text
Error parsing instance address: google_compute_instance

This command requires that the address references one specific instance.
To view the available instances, use "terraform state list". Please modify
the address to reference a specific instance.
```

This happened because `google_compute_instance` is only the resource type.

Terraform needs the full resource address.

The correct command is:

```bash
terraform state show google_compute_instance.vm_instance
```

This command showed detailed information about the VM, including:

- machine type
- zone
- internal IP
- boot disk
- subnet
- scheduling configuration
- shielded instance configuration

This was a useful mistake because it clarified the difference between:

```text
resource type
```

and:

```text
resource address
```

## Destroy the Infrastructure

Because this lab creates a VM, I destroyed the resources after testing.

Run:

```bash
terraform destroy
```

Terraform will ask for the project value again if it was not provided through another method.

Then it will show a destroy plan.

In my case, the destroy plan showed:

```text
Plan: 0 to add, 0 to change, 3 to destroy.
```

It also showed that outputs would be removed:

```text
Changes to Outputs:
  - lab_summary       = {...} -> null
  - vm_internal_ip    = "10.10.0.2" -> null
  - vpc_network_name  = "terraform-output-network" -> null
```

After reviewing the destroy plan, type:

```bash
yes
```

Important: wait until Terraform shows:

```text
Destroy complete! Resources: 3 destroyed.
```

After that, you can also verify from the Google Cloud Console that the VM, subnet, and VPC have been removed.

What I Learned

From this lab, I learned that Terraform outputs are not just decoration at the end of `terraform apply`.

Outputs are a clean way to expose the specific infrastructure values that matter.

Instead of manually searching through the state file or Google Cloud Console, I can query useful values directly:

```bash
terraform output
terraform output vm_internal_ip
terraform output lab_summary
terraform output -json
```

The most important idea for me is:

```text
Terraform creates infrastructure, state tracks infrastructure, and outputs expose selected infrastructure data.
```

I also learned that outputs can be simple values or structured objects.

For example, `vm_internal_ip` is a simple string output, while `lab_summary` is a structured output that groups multiple values together.

This makes outputs useful not only for humans, but also for automation.

## Next Step

This lab still asks me to manually enter the `project` variable during `terraform apply` and `terraform destroy`.

In the next lab, I want to improve that by using:

- `terraform.tfvars`
- `terraform.tfvars.example`
- safer variable value management
- avoiding repeated manual input

That should make the Terraform workflow cleaner and more practical.
