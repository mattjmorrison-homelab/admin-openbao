run "admin_cloudflare_kubernetes_auth_bindings_dropped_but_policies_still_exist" {
  command = plan

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "admin-cloudflare-tofu-state")
    error_message = "admin-cloudflare-tofu-state must no longer produce a Kubernetes-auth role binding -- every consumer migrated to OIDC"
  }

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "admin-cloudflare")
    error_message = "admin-cloudflare must no longer produce a Kubernetes-auth role binding -- every consumer migrated to OIDC"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "admin-cloudflare-tofu-state")
    error_message = "admin-cloudflare-tofu-state's policy must still exist -- the admin_cloudflare_tofu_state_oidc JWT role still reuses it by name"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "admin-cloudflare")
    error_message = "admin-cloudflare's policy must still exist -- the admin_cloudflare_oidc JWT role still reuses it by name"
  }
}
