# AppRole auth for the ad-reporter-investigate Claude Skill -- the second
# non-pod identity in this homelab (after nix-control-plane in
# approle.tf), reusing that same approle backend rather than standing up
# a second one. See ad-reporter-plan.md.
#
# Scoped to exactly the two KV paths the skill's own Discord-notify step
# needs -- same narrow, single-purpose grant shape as
# nix_control_plane_zot_readonly above, not a wildcard over the whole
# admin-discord or k8s-ad-reporter KV tree.
resource "vault_policy" "ad_reporter_skill" {
  name   = "ad-reporter-skill"
  policy = <<-EOT
    path "kv/data/homelab/service/admin-discord/k8s-ad-reporter/confirmed-webhook-url" {
      capabilities = ["read"]
    }
    path "kv/data/homelab/service/admin-discord/k8s-ad-reporter/suspicious-webhook-url" {
      capabilities = ["read"]
    }
  EOT
}

resource "vault_approle_auth_backend_role" "ad_reporter_skill" {
  backend        = vault_auth_backend.approle.path
  role_name      = "ad-reporter-skill"
  token_policies = [vault_policy.ad_reporter_skill.name]
  token_ttl      = 300
  token_max_ttl  = 600
  # secret_id never expires and is reusable across every scheduled skill
  # run (this is a long-lived machine identity, not a one-shot CI
  # credential) -- same reasoning as nix_control_plane_zot_readonly in
  # approle.tf. Rotation is a manual re-issue if the skill's copy is ever
  # suspected compromised.
  secret_id_ttl      = 0
  secret_id_num_uses = 0
}

output "ad_reporter_skill_role_id" {
  value       = vault_approle_auth_backend_role.ad_reporter_skill.role_id
  description = "Vault-generated role_id -- not sensitive on its own (no login without the separately-issued secret_id), safe to bake into the skill's own instructions as a plain literal."
}
