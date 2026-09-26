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
