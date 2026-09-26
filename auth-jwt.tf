# auth-jwt.tf
# GitHub Actions OIDC auth (todo #17) -- pilot on admin-github. Deliberately
# its own file/locals, not folded into locals.roles (Kubernetes-auth-role-
# shaped, doesn't apply here -- JWT-role binding is by token claim, not by
# ServiceAccount+namespace).
#
# Step 1 of the rollout: enable the mount and point it at GitHub's OIDC
# issuer so it can validate a real token's signature. The provider
# requires exactly one of oidc_discovery_url/jwks_url/jwks_pairs/
# jwt_validation_pubkeys at creation -- a truly empty mount isn't valid
# Terraform for this resource, confirmed the hard way. Still zero roles
# below, though -- nothing can actually log in yet.
resource "vault_jwt_auth_backend" "github_actions" {
  path               = "jwt"
  oidc_discovery_url = "https://token.actions.githubusercontent.com"
}

# Step 2 of the rollout: one role, pilot repo only. Reuses the existing
# admin-github-tofu-state policy by name -- same capability as the
# Kubernetes-auth role of the same name, only the login mechanism
# differs. role_type "jwt" (not "oidc") because GitHub presents an
# already-issued bearer token directly -- there's no browser
# authorization-code redirect flow here, which is what role_type "oidc"
# is for. bound_audiences must match whatever audience the workflow
# actually requests when it fetches its token (not yet built -- next
# step); "openbao" is an explicit, arbitrary literal chosen for this,
# not a GitHub default.
resource "vault_jwt_auth_backend_role" "admin_github_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-github-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-github"
  }
  user_claim     = "repository"
  token_policies = ["admin-github-tofu-state"]
  token_ttl      = 300
  token_max_ttl  = 600
}

# admin-cloudflare's CI does two separate logins today (Kubernetes-auth,
# one per policy) -- mirrored here as two JWT roles rather than
# consolidated into one, so the login mechanism changes but the
# capability shape (which policy each login call gets) doesn't.
resource "vault_jwt_auth_backend_role" "admin_cloudflare_tofu_state_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-cloudflare-tofu-state-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-cloudflare"
  }
  user_claim     = "repository"
  token_policies = ["admin-cloudflare-tofu-state"]
  token_ttl      = 300
  token_max_ttl  = 600
}

resource "vault_jwt_auth_backend_role" "admin_cloudflare_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-cloudflare-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-cloudflare"
  }
  user_claim     = "repository"
  token_policies = ["admin-cloudflare"]
  token_ttl      = 300
  token_max_ttl  = 600
}

# admin-discord's CI uses three separate policies today (read tofu-state
# creds, read the Discord bot token, write two consumers' webhook URLs
# back into OpenBao) -- mirrored here as three JWT roles, same
# one-role-per-policy convention as admin-cloudflare above.
resource "vault_jwt_auth_backend_role" "admin_discord_tofu_state_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-discord-tofu-state-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-discord"
  }
  user_claim     = "repository"
  token_policies = ["admin-discord-tofu-state"]
  token_ttl      = 300
  token_max_ttl  = 600
}

resource "vault_jwt_auth_backend_role" "admin_discord_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-discord-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-discord"
  }
  user_claim     = "repository"
  token_policies = ["admin-discord"]
  token_ttl      = 300
  token_max_ttl  = 600
}

resource "vault_jwt_auth_backend_role" "admin_discord_webhooks_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-discord-webhooks-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-discord"
  }
  user_claim     = "repository"
  token_policies = ["admin-discord-webhooks"]
  token_ttl      = 300
  token_max_ttl  = 600
}

# Self-referential (this repo defines its own migration credential), same
# as the Kubernetes-auth admin-openbao-tofu-state role it stands in for --
# governs admin-openbao's CI identity, not admin-openbao's own OpenBao
# management capabilities. Only one policy needed (tofu-state), unlike
# admin-discord's three -- same one-role-per-policy convention, just one
# policy here.
resource "vault_jwt_auth_backend_role" "admin_openbao_tofu_state_oidc" {
  backend         = vault_jwt_auth_backend.github_actions.path
  role_name       = "admin-openbao-tofu-state-oidc"
  role_type       = "jwt"
  bound_audiences = ["openbao"]
  bound_claims = {
    repository = "mattjmorrison-homelab/admin-openbao"
  }
  user_claim     = "repository"
  token_policies = ["admin-openbao-tofu-state"]
  token_ttl      = 300
  token_max_ttl  = 600
}
