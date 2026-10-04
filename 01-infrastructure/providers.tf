terraform {
  required_version = ">= 1.11" # write-only arguments, for the kubeconfig a drain uses

  # State in R2 beside core's, read with the r2 profile in ~/.aws/credentials
  # - see core/01-talos/README.md in the homelab repository. No lock table: one
  # administrator.
  backend "s3" {
    bucket                      = "homelab-backups"
    key                         = "terraform/lab-01-infrastructure.tfstate"
    region                      = "auto"
    endpoints                   = { s3 = "https://32bd020558a0bb7293a40decd3f7b161.r2.cloudflarestorage.com" }
    profile                     = "r2"
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true # R2 does not take the AWS SDK's default checksums
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.115.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "0.19.38"
    }
  }
}

# Terraform's token for the Proxmox API, root@pam!terraform, from Infisical:
# read for each run and never kept in the state (docs/decisions/0012).
ephemeral "infisical_secret" "proxmox_api_token" {
  workspace_id = local.infisical.project_id
  env_slug     = "prod"
  folder_path  = "/system/proxmox"
  name         = "API_TOKEN"
}

provider "proxmox" {
  endpoint  = local.proxmox.endpoint
  api_token = ephemeral.infisical_secret.proxmox_api_token.value
  insecure  = true # the host's self-signed certificate
}

# Infisical as the owner: the token of the CLI session `infisical login`
# opened, handed to each run by a terraform function in ~/.zshrc - nothing
# here or in a tfvars file. See README.md, "Infisical", and docs/decisions/0009.
provider "infisical" {}
