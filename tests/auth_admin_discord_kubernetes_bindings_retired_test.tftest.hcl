run "admin_discord_kubernetes_auth_bindings_dropped_but_policies_still_exist" {
  command = plan

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "admin-discord-tofu-state")
    error_message = "admin-discord-tofu-state must no longer produce a Kubernetes-auth role binding -- every consumer migrated to OIDC"
  }

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "admin-discord")
    error_message = "admin-discord must no longer produce a Kubernetes-auth role binding -- every consumer migrated to OIDC"
  }

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "admin-discord-webhooks")
    error_message = "admin-discord-webhooks must no longer produce a Kubernetes-auth role binding -- every consumer migrated to OIDC"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "admin-discord-tofu-state")
    error_message = "admin-discord-tofu-state's policy must still exist -- the admin_discord_tofu_state_oidc JWT role still reuses it by name"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "admin-discord")
    error_message = "admin-discord's policy must still exist -- the admin_discord_oidc JWT role still reuses it by name"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "admin-discord-webhooks")
    error_message = "admin-discord-webhooks's policy must still exist -- the admin_discord_webhooks_oidc JWT role still reuses it by name"
  }
}
