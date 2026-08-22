terraform {
  required_version = ">= 1.11.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0"
    }
  }

  # State lives in k8s-garage's tofu-state bucket, same pattern as
  # admin-github. Credentials come from AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY
  # env vars, not from this file.
  backend "s3" {
    bucket = "tofu-state"
    key    = "admin-openbao/terraform.tfstate"
    region = "garage"

    endpoints = {
      s3 = "http://garage.garage.svc.cluster.local:3900"
    }

    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

# VAULT_ADDR and VAULT_TOKEN come from the environment. VAULT_TOKEN is the
# root token generated at OpenBao's initial unseal (already saved in a
# password manager per homelab-openbao's README) -- this is the one
# credential in the whole homelab that can't be sourced from OpenBao
# itself, since it's what bootstraps access to OpenBao in the first place.
provider "vault" {}
