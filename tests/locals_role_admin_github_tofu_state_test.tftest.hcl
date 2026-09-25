run "admin_github_tofu_state_role_reads_only_its_own_dedicated_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-github-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-github/tofu-state-access-key-id")
    error_message = "admin-github-tofu-state role must grant read on its own tofu-state-access-key-id"
  }

  assert {
    condition     = strcontains(local.roles["admin-github-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-github/tofu-state-secret-access-key")
    error_message = "admin-github-tofu-state role must grant read on its own tofu-state-secret-access-key"
  }

  assert {
    condition     = local.roles["admin-github-tofu-state"].service_account == "github-runner-workload"
    error_message = "admin-github-tofu-state role must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }

  assert {
    condition     = strcontains(local.roles["admin-github-tofu-state"].policy, "kv/data/homelab/admin-github/github-token")
    error_message = "admin-github-tofu-state role must also grant read on admin-github/github-token -- unlike every other migrating repo, admin-github's own Terraform provider needs a GITHUB_TOKEN too"
  }
}
