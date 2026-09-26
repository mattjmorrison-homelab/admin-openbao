run "garage_policy_scoped_to_own_secrets_only" {
  command = plan

  assert {
    condition     = strcontains(local.roles["garage"].policy, "kv/data/homelab/k8s-garage/*")
    error_message = "garage policy must grant its own k8s-garage/* secrets"
  }

  assert {
    condition     = strcontains(local.roles["garage"].policy, "kv/data/homelab/service/k8s-garage/*")
    error_message = "garage policy must grant its own service/k8s-garage/* secrets"
  }

  assert {
    condition     = !strcontains(local.roles["garage"].policy, "kv/data/homelab/admin-github/tofu-state-access-key-id")
    error_message = "garage policy must not grant the old shared admin-github/tofu-state-access-key-id key -- dead, no script writes there anymore"
  }

  assert {
    condition     = !strcontains(local.roles["garage"].policy, "kv/data/homelab/admin-github/tofu-state-secret-access-key")
    error_message = "garage policy must not grant the old shared admin-github/tofu-state-secret-access-key key -- dead, no script writes there anymore"
  }

  assert {
    condition     = !strcontains(local.roles["garage"].policy, "kv/data/homelab/admin-github/*")
    error_message = "garage policy must not grant the admin-github/* wildcard -- it never touches github-token"
  }

  assert {
    condition     = !strcontains(local.roles["garage"].policy, "\"kv/data/homelab/garage\"") && !strcontains(local.roles["garage"].policy, "kv/data/homelab/garage/*") && !strcontains(local.roles["garage"].policy, "kv/data/homelab/gh-org")
    error_message = "garage policy must not grant the dead legacy bare garage/gh-org paths"
  }
}
