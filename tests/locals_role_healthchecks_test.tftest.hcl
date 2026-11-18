run "healthchecks_role_reads_only_its_own_two_secrets" {
  command = plan

  assert {
    condition     = local.roles["healthchecks"].namespace == "healthchecks"
    error_message = "healthchecks role must bind in the healthchecks namespace"
  }

  assert {
    condition     = local.roles["healthchecks"].service_account == "healthchecks"
    error_message = "healthchecks role must bind to the healthchecks ServiceAccount"
  }

  assert {
    condition     = strcontains(local.roles["healthchecks"].policy, "kv/data/homelab/k8s-healthchecks/secret-key")
    error_message = "healthchecks policy must grant read on secret-key"
  }

  assert {
    condition     = strcontains(local.roles["healthchecks"].policy, "kv/data/homelab/k8s-healthchecks/superuser-password")
    error_message = "healthchecks policy must grant read on superuser-password"
  }

  assert {
    condition     = !strcontains(local.roles["healthchecks"].policy, "create")
    error_message = "healthchecks (app) role must be read-only -- only healthchecks-bootstrap may write"
  }
}

run "healthchecks_bootstrap_role_can_mint_its_two_secrets" {
  command = plan

  assert {
    condition     = local.roles["healthchecks-bootstrap"].namespace == "healthchecks"
    error_message = "healthchecks-bootstrap role must bind in the healthchecks namespace"
  }

  assert {
    condition     = local.roles["healthchecks-bootstrap"].service_account == "healthchecks-bootstrap"
    error_message = "healthchecks-bootstrap role must bind to its own dedicated ServiceAccount, separate from the healthchecks runtime role"
  }

  assert {
    condition     = strcontains(local.roles["healthchecks-bootstrap"].policy, "kv/data/homelab/k8s-healthchecks/secret-key") && strcontains(local.roles["healthchecks-bootstrap"].policy, "create")
    error_message = "healthchecks-bootstrap policy must grant create/update on secret-key so a one-time init Job can mint it if missing"
  }

  assert {
    condition     = strcontains(local.roles["healthchecks-bootstrap"].policy, "kv/data/homelab/k8s-healthchecks/superuser-password") && strcontains(local.roles["healthchecks-bootstrap"].policy, "create")
    error_message = "healthchecks-bootstrap policy must grant create/update on superuser-password so a one-time init Job can mint it if missing"
  }
}

run "k8s_healthchecks_secrets_scaffolded" {
  command = plan

  assert {
    condition = alltrue([
      for key in ["secret-key", "superuser-password"] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-healthchecks/${key}")
    ])
    error_message = "k8s-healthchecks must scaffold both secret-key and superuser-password as blank KV paths"
  }
}
