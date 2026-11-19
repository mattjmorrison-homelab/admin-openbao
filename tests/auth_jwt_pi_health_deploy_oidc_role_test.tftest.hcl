run "pi_health_deploy_oidc_role_scoped_to_exactly_this_repo_reusing_the_existing_policy" {
  command = plan

  assert {
    condition     = vault_jwt_auth_backend_role.pi_health_deploy_oidc.role_type == "jwt"
    error_message = "must be role_type jwt (bearer-token validation), not oidc (browser authorization-code flow) -- GitHub presents an already-issued token directly"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.pi_health_deploy_oidc.bound_claims["repository"] == "mattjmorrison-homelab/pi-health"
    error_message = "must be bound to exactly the pi-health repo, not a wildcard or another repo"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.pi_health_deploy_oidc.token_policies, "pi-health-deploy")
    error_message = "must reuse the existing pi-health-deploy policy -- same capability as the Kubernetes-auth role, no new policy"
  }

  assert {
    condition     = length(vault_jwt_auth_backend_role.pi_health_deploy_oidc.token_policies) == 1
    error_message = "must grant exactly one policy -- no broader access than the Kubernetes-auth role it's standing in for"
  }
}
