# From PCA to Terraform: Provisioning My First GCP VPC with Infrastructure as Code

In my previous article, I documented how I installed Terraform on macOS using Homebrew and fixed a Zsh autocomplete issue.

In this article, I am going to be using terraform to provision, update, and destroy a simple set of infrastructure using the sample configuration provided by [hashicorp](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build)

The goal is to understand the basic Terraform workflow:

1. Write configuration
2. Authenticate to Google Cloud
3. Initialize Terraform
4. Format and validate the configuration
5. Review the execution plan
6. Apply the configuration
7. Inspect Terraform state
8. Destroy the infrastructure after the lab

## Prerequisites

- macOS
- Visual Studio Code
- Terraform CLI v1.15.1
- Google Cloud CLI installed locally
- A Google Cloud account
- A Google Cloud project with billing enabled
- Compute Engine API enabled

### Notes about Prerequisites

1. To install gcloud cli, go to [google cloud documentation](https://cloud.google.com/sdk/docs/install)
2. To install terraform, go to my previous [documentation about installation](https://dev.to/abrahamparn/installing-terraform-on-macos-with-homebrew-and-fixing-zsh-autocomplete-error-2gn9)

## Set up GCP

Before Terraform can create infrastructure in Google Cloud, we need to prepare the Google Cloud project.
For this lab, the project needs:

- A Google Cloud project
- Billing enabled
- Compute Engine API enabled

### Create or Select a Google Cloud Project

In the Google Cloud Console, open the project selector at the top of the page. From there, either select an existing project or create a new one. For this lab, make sure the selected project has billing enabled because Terraform will create Google Cloud resources inside the project.

### Enable the Compute Engine API

You can run the following commands either from your local terminal, if Google Cloud CLI is installed, or from Cloud Shell.

```bash
# make sure you are in the right project
gcloud config get-value project

# set the project config
gcloud config set project [YOUR_PROJECT_ID]

# run enablement
gcloud services enable compute.googleapis.com

# Verify enablement
gcloud services list --enabled --filter="name:compute.googleapis.com"
```

The response should be like this

```bash
NAME: compute.googleapis.com
TITLE: Compute Engine API
```

## Write the Terraform Configuration

Next, we will write our first Terraform configuration to create a Google Cloud VPC network.

Each Terraform configuration should be placed in its own working directory.

now, create the directory

```bash
mkdir learn-terraform-gcp
```

Move into the directory:

```bash
cd learn-terraform-gcp
```

Create a file called `main.tf`.

```bash
touch main.tf
```

The name `main.tf` is a common convention, but Terraform actually reads all `.tf` files in the current working directory.

Open the file using Visual Studio Code or your preferred editor, then add the following configuration:

```hcl
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "<PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

Replace `<PROJECT_ID>` with your actual Google Cloud project ID.

## Terraform Configuration Explanation

The `terraform {}` block contains Terraform-level settings.
In this example, it defines the required provider:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}
```

The provider source `hashicorp/google` is shorthand for

```bash
registry.terraform.io/hashicorp/google
```

This tells Terraform to use the official Google provider from the Terraform Registry.

### Required Provider

The `required_providers` block tells Terraform which provider plugin it needs to download.
In this case, Terraform needs the Google provider:

```hcl
google = {
  source  = "hashicorp/google"
  version = "6.8.0"
}
```

### Provider Configuration

The `provider "google"` block configures how Terraform connects to Google Cloud.

```hcl
provider "google" {
  project = "<PROJECT_ID>"
  region  = "us-central1"
  zone    = "us-central1-c"
}
```

In this lab, the provider is configured with:

- Google Cloud project ID
- Region
- Zone
  This tells Terraform where the infrastructure should be created.

### Resource Block

The `resource` block defines the infrastructure component that Terraform should manage.

```hcl
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
```

In this case:

- `google_compute_network` is the resource type
- `vpc_network` is the local Terraform name for the resource
- `terraform-network` is the actual VPC network name that will be created in Google Cloud

This resource creates a VPC network in the selected Google Cloud project.

## Authenticating to Google Cloud

Terraform must authenticate to Google Cloud before it can create infrastructure. In the terminal, run:

```bash
gcloud auth application-default login
```

Your browser will open and prompt you to log in to your Google Cloud account. After successful authentication, your terminal will display the path where the gcloud CLI saved your credentials.

The GCP provider automatically uses these credentials to authenticate against the Google Cloud APIs.

## Format the Configuration

Before initializing or applying the configuration, I ran:

```bash
terraform fmt
```

## Initialize the Directory

Next, initialize the Terraform working directory:

```shell
terraform init
```

This command prepares the working directory and downloads the provider plugins defined in the configuration.

Example output:

```bash
Initializing provider plugins found in the configuration...
- Finding hashicorp/google versions matching "6.8.0"...
- Installing hashicorp/google v6.8.0...
- Installed hashicorp/google v6.8.0 (signed by HashiCorp)

Initializing the backend...


Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

## Validate the configuration

After initialization, validate the configuration:

```bash
terraform validate
```

If the configuration is valid, the output should look like this:

```bash
Success! The configuration is valid.
```

Terraform returned an error like this:

```bash
│ Error: "name" ("terraform_network") doesn't match regexp "^(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?)$"
│
│   with google_compute_network.vpc_network,
│   on main.tf line 17, in resource "google_compute_network" "vpc_network":
│   17:   name = "terraform_network"
```

This happened because Google Cloud network names must follow a specific naming rule.
In this case, using:

```text
terraform-network
```

is valid, while:

```text
terraform_network
```

is not valid.

## Review the Execution Plan

Before creating the infrastructure, run:

```bash
terraform plan
```

This command shows what Terraform intends to create, update, or destroy.

For this lab, Terraform planned to create one resource:

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

This is one of the most important Terraform habits.

The plan phase is the safety checkpoint.

Before applying any change, I should understand whether Terraform is going to:

- create a resource
- update a resource
- replace a resource
- destroy a resource

For this first lab, the plan is simple. But in a real environment, reviewing the Terraform plan carefully is critical.

## Create the Infrastructure

After reviewing the plan, apply the configuration:

```bash
terraform apply
```

Terraform will show the execution plan again and ask for confirmation.

the output usually like this

```bash
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_network.vpc_network will be created
  + resource "google_compute_network" "vpc_network" {
      + auto_create_subnetworks                   = true
      + delete_default_routes_on_create           = false
      + gateway_ipv4                              = (known after apply)
      + id                                        = (known after apply)
      + internal_ipv6_range                       = (known after apply)
      + mtu                                       = (known after apply)
      + name                                      = "terraform-network"
      + network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
      + numeric_id                                = (known after apply)
      + project                                   = "terraform-gcp-learning-lab"
      + routing_mode                              = (known after apply)
      + self_link                                 = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

now you enter value of `yes`

```bash
Enter a value: yes
```

## Inspect Terraform State

Terraform state stores the IDs and properties of the resources that Terraform manages.

This allows Terraform to understand the relationship between the configuration file and the actual infrastructure in Google Cloud.

Inspect the current state:

```bash
terraform show
```

the response should be like this

```bash
# google_compute_network.vpc_network:
resource "google_compute_network" "vpc_network" {
    auto_create_subnetworks                   = true
    delete_default_routes_on_create           = false
    description                               = null
    enable_ula_internal_ipv6                  = false
    gateway_ipv4                              = null
    id                                        = "projects/terraform-gcp-learning-lab/global/networks/terraform-network"
    internal_ipv6_range                       = null
    mtu                                       = 0
    name                                      = "terraform-network"
    network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
    numeric_id                                = "2818444064827549422"
    project                                   = "terraform-gcp-learning-lab"
    routing_mode                              = "REGIONAL"
    self_link                                 = "https://www.googleapis.com/compute/v1/projects/terraform-gcp-learning-lab/global/networks/terraform-network"
```

This was one of the most important lessons from this lab.

Terraform is not only a tool that creates infrastructure. Terraform also tracks the infrastructure it manages through state.

For this beginner lab, the state is stored locally in:

```text
terraform.tfstate
```

## Check the Resource in Google Cloud Console

After Terraform finishes creating the VPC network, you can verify it in the Google Cloud Console.

Go to:

```text
VPC network > VPC networks
```

You should see a network named:

```text
terraform-network
```

At this point, the VPC exists in Google Cloud and is being managed by Terraform.

## Destroy everything

Because this is only a learning lab, I do not want to leave unused resources running in my Google Cloud project.

To destroy the infrastructure managed by this Terraform configuration, run:

```bash
terraform destroy
```

Terraform will show a destroy plan and ask for confirmation.

Type:

```bash
yes
```

Important note: `terraform destroy` only destroys resources managed by the current Terraform state.

In this lab, it will destroy the VPC network created by this configuration.

After the destroy process is complete, you can check the Google Cloud Console again to confirm that the VPC network has been removed.
