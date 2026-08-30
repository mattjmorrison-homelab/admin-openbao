# approle.tf
# AppRole auth for the nix-control-plane host -- the one non-pod identity
# in this homelab. Deliberately its own file/locals, not folded into
# locals.roles (Kubernetes-auth-role-shaped, doesn't apply here).
#
# Scoped to exactly one KV path -- this is a narrower grant than every
# other role in this repo (which grant `path` + `path/*`), because this
# credential exists for exactly one purpose and nothing else should ever
# widen it silently.
resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_policy" "nix_control_plane_zot_readonly" {
  name   = "nix-control-plane-zot-readonly"
  policy = <<-EOT
    path "kv/data/homelab/homelab/zot-readonly-password" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_approle_auth_backend_role" "nix_control_plane_zot_readonly" {
  backend        = vault_auth_backend.approle.path
  role_name      = "nix-control-plane-zot-readonly"
  token_policies = [vault_policy.nix_control_plane_zot_readonly.name]
  token_ttl      = 300
  token_max_ttl  = 600
  # secret_id never expires and is reusable across every scheduled sync run
  # (this is a long-lived machine identity, not a one-shot CI credential) --
  # rotation is a manual re-issue if the host's copy is ever suspected
  # compromised, same shape as every other bootstrap credential in this repo.
  secret_id_ttl      = 0
  secret_id_num_uses = 0
}

output "nix_control_plane_zot_readonly_role_id" {
  value       = vault_approle_auth_backend_role.nix_control_plane_zot_readonly.role_id
  description = "Vault-generated role_id -- not sensitive on its own (no login without the separately-issued secret_id), safe to bake into homelab's Nix module as a plain literal."
}
