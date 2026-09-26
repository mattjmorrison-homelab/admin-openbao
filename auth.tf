resource "vault_policy" "roles" {
  for_each = local.roles

  name   = each.key
  policy = each.value.policy
}

# Opt-out via kubernetes_auth = false, not opt-in -- a role that migrates
# to a different auth method (OIDC, todo #17) still needs its policy
# (vault_policy.roles above, unconditional over the whole map), just not
# this specific Kubernetes-auth binding to it anymore. try() defaults
# every entry without the field set to true, so this changes nothing for
# any role that hasn't explicitly opted out.
resource "vault_kubernetes_auth_backend_role" "roles" {
  for_each = { for k, v in local.roles : k => v if try(v.kubernetes_auth, true) }

  backend                          = "kubernetes"
  role_name                        = each.key
  bound_service_account_names      = [each.value.service_account]
  bound_service_account_namespaces = [each.value.namespace]
  token_policies                   = [each.key]
}
