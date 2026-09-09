run "admin_cloudflare_role_reads_only_its_two_exact_keys" {
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
    condition     = strcontains(local.roles["admin-cloudflare"].policy, "kv/data/homelab/k8s-cloudflare/cloudflare-api-token")
    error_message = "admin-cloudflare policy must grant read on the real cloudflare-api-token key"
  }

  assert {
    condition     = strcontains(local.roles["admin-cloudflare"].policy, "kv/data/homelab/k8s-cloudflare/cf-account-id")
    error_message = "admin-cloudflare policy must grant read on the real cf-account-id key"
  }

  assert {
    condition     = !strcontains(local.roles["admin-cloudflare"].policy, "kv/data/homelab/k8s-cloudflare/*") && !strcontains(local.roles["admin-cloudflare"].policy, "\"kv/data/homelab/k8s-cloudflare\"")
    error_message = "admin-cloudflare must not get the k8s-cloudflare/* wildcard -- it never touches tunnel-id, tunnel-secret, or account-tag, which stay exclusive to cloudflare-bootstrap"
  }

  assert {
    condition     = !strcontains(local.roles["admin-cloudflare"].policy, "create") && !strcontains(local.roles["admin-cloudflare"].policy, "update")
    error_message = "admin-cloudflare policy must be read-only -- it only ever reads these to authenticate the Cloudflare provider, never writes them"
  }
}
