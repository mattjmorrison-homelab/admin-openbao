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
