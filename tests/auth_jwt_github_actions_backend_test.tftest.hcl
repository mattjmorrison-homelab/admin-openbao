run "jwt_auth_backend_mounted_and_trusts_github_actions_issuer" {
  command = plan

  assert {
    condition     = vault_jwt_auth_backend.github_actions.path == "jwt"
    error_message = "the JWT auth backend must be mounted at path 'jwt'"
  }

  assert {
    condition     = vault_jwt_auth_backend.github_actions.oidc_discovery_url == "https://token.actions.githubusercontent.com"
    error_message = "the JWT auth backend must trust GitHub Actions' own OIDC issuer, not something else"
  }
}
