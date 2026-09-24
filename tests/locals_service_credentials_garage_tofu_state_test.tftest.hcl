run "garage_scaffolds_per_repo_tofu_state_creds_for_all_4_repos" {
  command = plan

  assert {
    condition = alltrue([
      for consumer_cred in [
        "admin-discord/tofu-state-access-key-id",
        "admin-discord/tofu-state-secret-access-key",
        "admin-github/tofu-state-access-key-id",
        "admin-github/tofu-state-secret-access-key",
        "admin-openbao/tofu-state-access-key-id",
        "admin-openbao/tofu-state-secret-access-key",
        "admin-cloudflare/tofu-state-access-key-id",
        "admin-cloudflare/tofu-state-secret-access-key",
      ] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], "service/k8s-garage/${consumer_cred}")
    ])
    error_message = "local.secrets must scaffold per-repo tofu-state credentials for all 4 Terraform repos on the shared bucket (confirmed via grepping every provider.tf for backend \"s3\")"
  }
}

run "garage_role_can_write_its_own_service_subtree" {
  command = plan

  assert {
    condition     = strcontains(local.roles["garage"].policy, "kv/data/homelab/service/k8s-garage/*")
    error_message = "garage role must be able to create/update its own service/k8s-garage/* subtree, to write the per-repo tofu-state credentials it mints"
  }
}
