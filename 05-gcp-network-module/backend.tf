terraform {
  backend "gcs" {
    bucket = "terraform-gcp-learning-lab-terraform-state"
    prefix = "terraform-gcp-learning-lab/05-gcp-network-module"
  }
}

