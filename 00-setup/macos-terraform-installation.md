# macOS Terraform Installation Notes

## Install HashiCorp Tap

```bash
brew tap hashicorp/tap
```

## Install Terraform

```bash
brew install hashicorp/tap/terraform
```

## Verify Installation

```bash
terraform --version
terraform --help
terraform plan -help
```

## Enable Zsh Autocomplete

```bash
touch ~/.zshrc
terraform -install-autocomplete
source ~/.zshrc
```

## Error encountered

```bash
complete:13: command not found: compdef
```

## Fix

Open `.zshrc`:

```bash
nano ~/.zshrc
```

add

```bash
autoload -Uz compinit && compinit
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform
```

Check Terraform path:

```bash
which terraform
```

Use the returned path in the autocomplete command.
