run "pi_health_deploy_kubernetes_auth_binding_dropped_but_policy_still_exists" {
  command = plan

  assert {
    condition     = !contains([for k, v in vault_kubernetes_auth_backend_role.roles : k], "pi-health-deploy")
    error_message = "pi-health-deploy must no longer produce a Kubernetes-auth role binding -- its only consumer migrated to OIDC"
  }

  assert {
    condition     = contains([for k, v in vault_policy.roles : k], "pi-health-deploy")
    error_message = "pi-health-deploy's policy must still exist -- the pi-health-deploy-oidc JWT role still reuses it by name"
  }
}
