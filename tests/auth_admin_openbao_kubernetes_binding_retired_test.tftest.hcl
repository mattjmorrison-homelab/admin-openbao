run "admin_openbao_kubernetes_auth_binding_dropped_but_policy_still_exists" {
  command = plan

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "admin-openbao-tofu-state")
    error_message = "admin-openbao-tofu-state must no longer produce a Kubernetes-auth role binding -- every consumer migrated to OIDC"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "admin-openbao-tofu-state")
    error_message = "admin-openbao-tofu-state's policy must still exist -- the admin_openbao_tofu_state_oidc JWT role still reuses it by name"
  }
}
