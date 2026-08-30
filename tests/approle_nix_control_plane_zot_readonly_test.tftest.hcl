run "approle_role_scoped_to_single_zot_readonly_path" {
  command = plan

  assert {
    condition     = strcontains(vault_policy.nix_control_plane_zot_readonly.policy, "kv/data/homelab/homelab/zot-readonly-password")
    error_message = "policy must grant the zot-readonly-password path"
  }

  assert {
    condition     = !strcontains(vault_policy.nix_control_plane_zot_readonly.policy, "/*")
    error_message = "policy must NOT use a wildcard -- this credential is scoped to exactly one secret, not a whole app's KV tree"
  }
}
