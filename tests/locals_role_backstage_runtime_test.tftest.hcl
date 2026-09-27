run "backstage_runtime_role_reads_only_its_own_secrets" {
  command = plan

  assert {
    condition     = local.roles["backstage"].namespace == "backstage"
    error_message = "backstage role must bind to the backstage namespace"
  }
  assert {
    condition     = local.roles["backstage"].service_account == "backstage"
    error_message = "backstage role must bind to the backstage ServiceAccount, matching the single-workload-app convention"
  }
  assert {
    condition     = strcontains(local.roles["backstage"].policy, "kv/data/homelab/k8s-backstage/*")
    error_message = "backstage role must grant read on k8s-backstage/*"
  }
}

run "k8s_backstage_runtime_secrets_scaffolded" {
  command = plan

  assert {
    condition = alltrue([
      for key in ["postgres-password", "backend-auth-key"] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-backstage/${key}")
    ])
    error_message = "k8s-backstage must scaffold postgres-password and backend-auth-key"
  }
}
