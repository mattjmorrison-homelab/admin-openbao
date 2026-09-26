run "admin_discord_oidc_roles_scoped_to_exactly_this_repo_each_reusing_its_own_existing_policy" {
  command = plan

  assert {
    condition     = vault_jwt_auth_backend_role.admin_discord_tofu_state_oidc.bound_claims["repository"] == "mattjmorrison-homelab/admin-discord"
    error_message = "tofu-state role must be bound to exactly the admin-discord repo"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.admin_discord_oidc.bound_claims["repository"] == "mattjmorrison-homelab/admin-discord"
    error_message = "bot-token role must be bound to exactly the admin-discord repo"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.admin_discord_webhooks_oidc.bound_claims["repository"] == "mattjmorrison-homelab/admin-discord"
    error_message = "webhooks role must be bound to exactly the admin-discord repo"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.admin_discord_tofu_state_oidc.token_policies, "admin-discord-tofu-state") && length(vault_jwt_auth_backend_role.admin_discord_tofu_state_oidc.token_policies) == 1
    error_message = "tofu-state role must grant exactly the existing admin-discord-tofu-state policy"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.admin_discord_oidc.token_policies, "admin-discord") && length(vault_jwt_auth_backend_role.admin_discord_oidc.token_policies) == 1
    error_message = "bot-token role must grant exactly the existing admin-discord policy"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.admin_discord_webhooks_oidc.token_policies, "admin-discord-webhooks") && length(vault_jwt_auth_backend_role.admin_discord_webhooks_oidc.token_policies) == 1
    error_message = "webhooks role must grant exactly the existing admin-discord-webhooks policy -- write access stays as narrow as it is today"
  }
}
