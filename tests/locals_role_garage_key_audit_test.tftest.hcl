run "garage_key_audit_role_is_read_only_and_scoped_to_admin_token" {
  command = plan

  assert {
    condition     = local.roles["garage-key-audit"].namespace == "github-runner"
    error_message = "garage-key-audit role must bind in the github-runner namespace, same as every other CI-fetch role"
  }

  assert {
    condition     = local.roles["garage-key-audit"].service_account == "github-runner-workload"
    error_message = "garage-key-audit role must bind to the shared github-runner-workload identity"
  }

  assert {
    condition     = strcontains(local.roles["garage-key-audit"].policy, "kv/data/homelab/k8s-garage/admin-token")
    error_message = "garage-key-audit policy must grant read on exactly k8s-garage/admin-token"
  }

  assert {
    condition     = !strcontains(local.roles["garage-key-audit"].policy, "create") && !strcontains(local.roles["garage-key-audit"].policy, "update")
    error_message = "garage-key-audit policy must be read-only -- this is a diagnostic-only role"
  }
}
