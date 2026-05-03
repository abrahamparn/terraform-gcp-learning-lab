# Installing Terraform on macOS with Homebrew and Fixing Zsh Autocomplete Error

After passing Google Professional Cloud Architect, I started learning Terraform to turn cloud architecture knowledge into reproducible Infrastructure as Code.

This is my first Terraform learning note with a simple goal of

- install Terraform on macOS
- verify that it works
- enable autocomplete
- document one error I encountered during setup

## Requirements

For this setup, I used Homebrew.
If you do not have Homebrew installed yet, you can install it from:
`https://brew.sh/`

## What is Homebrew?

Small info, Homebrew is a package manager for macOS and Linux. It helps install, update, and manage developer tools directly from the terminal.

> Reference: This note is based on HashiCorp’s official Terraform installation guide. I rewrote the steps in my own words as part of my personal Terraform learning documentation.

## Install Terraform on macOS

First, add HashiCorp’s official Homebrew tap.

```bash
brew tap hashicorp/tap
```

### Verify the Installation

After installation, check whether Terraform is available.

```bash
terraform --version
```

You can also list Terraform’s available commands.

```bash
terraform --help
```

To inspect a specific command, add `-help`. For example:

```bash
terraform plan -help
```

## Enable Terraform Autocomplete

Because I am using Zsh on macOS, I first made sure that the Zsh configuration file exists.

```bash
touch ~/.zshrc
```

Or if you are not too sure, go check it with

```bash
ls -la .zshrc
```

It will output the path to that file.

Then I installed Terraform autocomplete.

```bash
terraform -install-autocomplete
```

After installing autocomplete, restart the shell or reload the Zsh configuration.

```bash
source ~/.zshrc
```

## The Error

After running terraform -install-autocomplete, I encountered this error when opening a new terminal window:

```bash
complete:13: command not found: compdef
```

### Why This Happened

Terraform autocomplete uses shell completion.

In my case, Zsh’s completion system was not properly initialized before Terraform’s autocomplete command was loaded.

Because of that, the terminal could not recognize `compdef`.

### The Fix

Open the Zsh configuration file.

```bash
nano ~/.zshrc
```

Then make sure the Zsh completion system is initialized before the Terraform autocomplete line.

My configuration looked like this:

```bash
# Initialize Zsh completion system
autoload -Uz compinit && compinit

# Initialize Bash completion compatibility
autoload -U +X bashcompinit && bashcompinit

# Terraform CLI autocomplete
complete -o nospace -C /opt/homebrew/bin/terraform terraform
```

Important note: the Terraform path may be different depending on your Mac.

To check your Terraform path, run:

```bash
which terraform
```

For Apple Silicon Macs, it is commonly:

```bash
/opt/homebrew/bin/terraform
```

Use the path returned by `which terraform`.

## Restart the Shell

After updating `.zshrc`, reload it:

```bash
source ~/.zshrc
```

## Test Autocomplete

Type this without pressing Enter:

```bash
terraform provi
```

Then press `tab`. The result should usually be

```bash
terraform providers
```

## What I Learned

This was a small setup issue, but it reminded me of an important Infrastructure as Code principle:

Tooling setup matters.

This is only the first step. Next, I will start learning Terraform providers, resources, variables, outputs, and how Terraform works with Google Cloud.
