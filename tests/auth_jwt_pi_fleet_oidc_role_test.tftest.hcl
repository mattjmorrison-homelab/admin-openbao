run "pi_fleet_oidc_role_scoped_to_exactly_this_repo_reusing_the_existing_policy" {
  command = plan

  assert {
    condition     = vault_jwt_auth_backend_role.pi_fleet_oidc.role_type == "jwt"
    error_message = "must be role_type jwt (bearer-token validation), not oidc (browser authorization-code flow) -- GitHub presents an already-issued token directly"
  }

  assert {
    condition     = vault_jwt_auth_backend_role.pi_fleet_oidc.bound_claims["repository"] == "mattjmorrison-homelab/pi-fleet"
    error_message = "must be bound to exactly the pi-fleet repo, not a wildcard or another repo"
  }

  assert {
    condition     = contains(vault_jwt_auth_backend_role.pi_fleet_oidc.token_policies, "pi-fleet")
    error_message = "must reuse the pi-fleet policy -- the one that grants ssh/sign/pi-fleet"
  }

  assert {
    condition     = length(vault_jwt_auth_backend_role.pi_fleet_oidc.token_policies) == 1
    error_message = "must grant exactly one policy -- no broader access than signing its own SSH role"
  }
}
