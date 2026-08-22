resource "vault_policy" "roles" {
  for_each = local.roles

  name   = each.key
  policy = each.value.policy
}

resource "vault_kubernetes_auth_backend_role" "roles" {
  for_each = local.roles

  backend                          = "kubernetes"
  role_name                        = each.key
  bound_service_account_names      = [each.value.service_account]
  bound_service_account_namespaces = [each.value.namespace]
  token_policies                   = [each.key]
}
