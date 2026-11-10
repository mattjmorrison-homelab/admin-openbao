run "ad_reporter_skill_approle_reuses_the_existing_backend_and_is_scoped_to_its_two_webhook_paths" {
  command = plan

  assert {
    condition     = strcontains(vault_policy.ad_reporter_skill.policy, "kv/data/homelab/service/admin-discord/k8s-ad-reporter/confirmed-webhook-url")
    error_message = "policy must grant read on the confirmed-webhook-url path"
  }

  assert {
    condition     = strcontains(vault_policy.ad_reporter_skill.policy, "kv/data/homelab/service/admin-discord/k8s-ad-reporter/suspicious-webhook-url")
    error_message = "policy must grant read on the suspicious-webhook-url path"
  }

  assert {
    condition     = contains(vault_approle_auth_backend_role.ad_reporter_skill.token_policies, vault_policy.ad_reporter_skill.name) && length(vault_approle_auth_backend_role.ad_reporter_skill.token_policies) == 1
    error_message = "role must grant exactly its own policy, nothing broader"
  }
}

run "ad_reporter_skill_approle_is_long_lived_same_as_nix_control_plane" {
  command = plan

  assert {
    condition     = vault_approle_auth_backend_role.ad_reporter_skill.secret_id_ttl == 0 && vault_approle_auth_backend_role.ad_reporter_skill.secret_id_num_uses == 0
    error_message = "secret_id must never expire and be reusable -- this is a long-lived scheduled-skill machine identity, same as nix-control-plane"
  }

  assert {
    condition     = vault_approle_auth_backend_role.ad_reporter_skill.token_ttl == 300 && vault_approle_auth_backend_role.ad_reporter_skill.token_max_ttl == 600
    error_message = "token TTLs must match nix-control-plane's shape (300/600)"
  }
}
