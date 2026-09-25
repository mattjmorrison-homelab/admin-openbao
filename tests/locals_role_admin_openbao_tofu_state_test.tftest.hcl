run "admin_openbao_tofu_state_role_reads_only_its_own_dedicated_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-openbao-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-openbao/tofu-state-access-key-id")
    error_message = "admin-openbao-tofu-state role must grant read on its own tofu-state-access-key-id"
  }

  assert {
    condition     = strcontains(local.roles["admin-openbao-tofu-state"].policy, "kv/data/homelab/service/k8s-garage/admin-openbao/tofu-state-secret-access-key")
    error_message = "admin-openbao-tofu-state role must grant read on its own tofu-state-secret-access-key"
  }

  assert {
    condition     = local.roles["admin-openbao-tofu-state"].service_account == "github-runner-workload"
    error_message = "admin-openbao-tofu-state role must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }
}
