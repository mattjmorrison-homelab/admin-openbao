run "admin_discord_tofu_state_role_reads_only_its_own_dedicated_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-discord/tofu-state-access-key-id")
    error_message = "admin-discord-tofu-state role must grant read on its own tofu-state-access-key-id"
  }

  assert {
    condition     = strcontains(local.roles["admin-discord-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-discord/tofu-state-secret-access-key")
    error_message = "admin-discord-tofu-state role must grant read on its own tofu-state-secret-access-key"
  }

  assert {
    condition     = !strcontains(local.roles["admin-discord-tofu-state"].policy, "admin-github")
    error_message = "admin-discord-tofu-state role must not read admin-github's shared bucket credentials"
  }

  assert {
    condition     = local.roles["admin-discord-tofu-state"].service_account == "github-runner-workload"
    error_message = "admin-discord-tofu-state role must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }
}
