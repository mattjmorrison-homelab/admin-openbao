run "admin_cloudflare_oidc_roles_scoped_to_exactly_this_repo_each_reusing_its_own_existing_policy" {
  command = plan

  assert {
    condition     = vault_jwt_auth_backend_role.admin_cloudflare_tofu_state_oidc.bound_claims["repository"] == "mattjmorrison-homelab/admin-cloudflare"
    error_message = "tofu-state role must be bound to exactly the admin-cloudflare repo"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.admin_cloudflare_oidc.bound_claims["repository"] == "mattjmorrison-homelab/admin-cloudflare"
    error_message = "cloudflare-api role must be bound to exactly the admin-cloudflare repo"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.admin_cloudflare_tofu_state_oidc.token_policies, "admin-cloudflare-tofu-state") && length(vault_jwt_auth_backend_role.admin_cloudflare_tofu_state_oidc.token_policies) == 1
    error_message = "tofu-state role must grant exactly the existing admin-cloudflare-tofu-state policy -- no capability change from the Kubernetes-auth role it replaces"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.admin_cloudflare_oidc.token_policies, "admin-cloudflare") && length(vault_jwt_auth_backend_role.admin_cloudflare_oidc.token_policies) == 1
    error_message = "cloudflare-api role must grant exactly the existing admin-cloudflare policy -- no capability change from the Kubernetes-auth role it replaces"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.admin_cloudflare_tofu_state_oidc.role_name != vault_jwt_auth_backend_role.admin_cloudflare_oidc.role_name
    error_message = "the two roles must stay distinct -- separate policies mean separate logins, not one consolidated role"
  }
}
