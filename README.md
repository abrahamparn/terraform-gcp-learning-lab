# Terraform x Google Cloud Learning Lab

After passing Google Associate Cloud Engineer and Google Professional Cloud Architect, I started this repository to document my Terraform learning journey.

The goal is not only to prepare for the Terraform Associate certification, but also to convert cloud architecture knowledge into practical, reproducible Infrastructure as Code.

## Objectives

- Learn Terraform fundamentals
- Practice Terraform with Google Cloud
- Build reusable Infrastructure as Code examples
- Understand Terraform state, providers, resources, variables, outputs, and modules
- Document real setup issues and operational lessons
- Build public artifacts for SRE / Cloud Engineering portfolio development

## Learning Roadmap

### 00 - Setup

- Install Terraform on macOS
- Configure shell autocomplete
- Document terminal errors and fixes

### 01 - Terraform Basics

- Terraform CLI workflow
- Providers
- Resources
- Variables
- Outputs
- Locals
- State basics

### 02 - Google Cloud Provider

- Configure the Google provider
- Authenticate with Google Cloud
- Create basic GCP resources using Terraform

### 03 - Remote State

- Store Terraform state in Google Cloud Storage
- Understand state locking and versioning
- Avoid local-only state for team workflows

### 04 - GCP Networking

- Create VPC
- Create subnets
- Create firewall rules
- Understand public and private infrastructure boundaries

### 05 - CI/CD

- Run terraform fmt
- Run terraform validate
- Run terraform plan in CI
- Apply infrastructure changes through a controlled workflow

## Published Articles

1. Installing Terraform on macOS with Homebrew and Fixing Zsh Autocomplete Error

## Status

This repository is a work in progress and will be updated as I continue learning Terraform with Google Cloud.
