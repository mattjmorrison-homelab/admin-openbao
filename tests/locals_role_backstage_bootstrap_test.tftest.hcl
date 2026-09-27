run "backstage_bootstrap_role_writes_only_its_two_specific_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["backstage-bootstrap"].policy, "kv/data/homelab/k8s-backstage/postgres-password")
    error_message = "backstage-bootstrap must grant create/update on postgres-password"
  }
  assert {
    condition     = strcontains(local.roles["backstage-bootstrap"].policy, "kv/data/homelab/k8s-backstage/backend-auth-key")
    error_message = "backstage-bootstrap must grant create/update on backend-auth-key"
  }
  assert {
    condition     = !strcontains(local.roles["backstage-bootstrap"].policy, "k8s-backstage/*")
    error_message = "backstage-bootstrap must not have a broad k8s-backstage/* grant -- only these two exact paths"
  }
  assert {
    condition     = local.roles["backstage-bootstrap"].service_account == "backstage-bootstrap"
    error_message = "backstage-bootstrap role must bind to its own dedicated ServiceAccount, separate from the backstage runtime role"
  }
}
