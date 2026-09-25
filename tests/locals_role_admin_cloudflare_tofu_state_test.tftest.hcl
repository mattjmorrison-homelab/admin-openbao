run "admin_cloudflare_tofu_state_role_reads_only_its_own_dedicated_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-cloudflare-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-cloudflare/tofu-state-access-key-id")
    error_message = "admin-cloudflare-tofu-state role must grant read on its own tofu-state-access-key-id"
  }

  assert {
    condition     = strcontains(local.roles["admin-cloudflare-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-cloudflare/tofu-state-secret-access-key")
    error_message = "admin-cloudflare-tofu-state role must grant read on its own tofu-state-secret-access-key"
  }

  assert {
    condition     = local.roles["admin-cloudflare-tofu-state"].service_account == "github-runner-workload"
    error_message = "admin-cloudflare-tofu-state role must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }

  assert {
    condition     = !strcontains(local.roles["admin-cloudflare-tofu-state"].policy, "cloudflare-api-token")
    error_message = "admin-cloudflare-tofu-state role must be separate from the existing admin-cloudflare role -- purely tofu-state, not cloudflare-api-token/cf-account-id"
  }
}
