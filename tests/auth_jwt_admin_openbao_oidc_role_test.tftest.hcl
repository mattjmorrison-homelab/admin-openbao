run "admin_openbao_oidc_role_scoped_to_exactly_this_repo_reusing_the_existing_policy" {
  command = plan

  assert {
    condition     = vault_jwt_auth_backend_role.admin_openbao_tofu_state_oidc.role_type == "jwt"
    error_message = "must be role_type jwt (bearer-token validation), not oidc (browser authorization-code flow) -- GitHub presents an already-issued token directly"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.admin_openbao_tofu_state_oidc.bound_claims["repository"] == "mattjmorrison-homelab/admin-openbao"
    error_message = "must be bound to exactly the admin-openbao repo, not a wildcard or another repo"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.admin_openbao_tofu_state_oidc.token_policies, "admin-openbao-tofu-state")
    error_message = "must reuse the existing admin-openbao-tofu-state policy -- same capability as the Kubernetes-auth role, no new policy"
  }

  assert {
    condition     = length(vault_jwt_auth_backend_role.admin_openbao_tofu_state_oidc.token_policies) == 1
    error_message = "must grant exactly one policy -- no broader access than the Kubernetes-auth role it's standing in for"
  }
}
