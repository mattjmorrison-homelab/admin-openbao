run "garage_policy_scoped_to_own_secrets_and_exact_tofu_state_keys" {
  command = plan

  assert {
    condition     = strcontains(local.roles["garage"].policy, "kv/data/homelab/k8s-garage/*")
    error_message = "garage policy must grant its own k8s-garage/* secrets"
  }

  assert {
    condition     = strcontains(local.roles["garage"].policy, "kv/data/homelab/admin-github/tofu-state-access-key-id")
    error_message = "garage policy must grant its exact tofu-state-access-key-id key"
  }

  assert {
    condition     = strcontains(local.roles["garage"].policy, "kv/data/homelab/admin-github/tofu-state-secret-access-key")
    error_message = "garage policy must grant its exact tofu-state-secret-access-key key"
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
