run "admin_cloudflare_role_reads_only_its_own_dedicated_credential" {
  command = plan

  assert {
    condition     = local.roles["admin-cloudflare"].namespace == "github-runner"
    error_message = "admin-cloudflare's CI runs as github-runner-workload, same as every other Terraform repo's role, until the per-repo ServiceAccount migration lands"
  }

  assert {
    condition     = local.roles["admin-cloudflare"].service_account == "github-runner-workload"
    error_message = "admin-cloudflare must bind to the shared github-runner-workload identity, not a dedicated SA that doesn't exist yet"
  }

  assert {
    condition     = strcontains(local.roles["admin-cloudflare"].policy, "kv/data/homelab/admin-cloudflare/*")
    error_message = "admin-cloudflare policy must grant read on its own dedicated admin-cloudflare/* secrets"
  }

  assert {
    condition     = !strcontains(local.roles["admin-cloudflare"].policy, "k8s-cloudflare")
    error_message = "admin-cloudflare must never read k8s-cloudflare's own credentials -- it needs its own separate, narrower-scoped Cloudflare API token, not a shared one"
  }

  assert {
    condition     = !strcontains(local.roles["admin-cloudflare"].policy, "create") && !strcontains(local.roles["admin-cloudflare"].policy, "update")
    error_message = "admin-cloudflare policy must be read-only -- it only ever reads these to authenticate the Cloudflare provider, never writes them"
  }
}

run "admin_cloudflare_service_credentials_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "admin-cloudflare/cloudflare-api-token")
    error_message = "local.secrets must scaffold admin-cloudflare's own dedicated cloudflare-api-token"
  }

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "admin-cloudflare/cf-account-id")
    error_message = "local.secrets must scaffold admin-cloudflare's own dedicated cf-account-id"
  }
}
