run "zot_verify_role_is_read_only_and_scoped_to_its_own_dedicated_credential" {
  command = plan

  assert {
    condition     = local.roles["zot-verify"].namespace == "zot"
    error_message = "zot-verify role must bind in the zot namespace"
  }

  assert {
    condition     = local.roles["zot-verify"].service_account == "zot-verify"
    error_message = "zot-verify role must bind to its own dedicated zot-verify ServiceAccount, not zot-bootstrap or zot's own read-only one"
  }

  assert {
    condition     = strcontains(local.roles["zot-verify"].policy, "kv/data/homelab/service/k8s-zot/zot-verify/verify-password")
    error_message = "zot-verify policy must grant read on its own dedicated service-credential path, not a shared account like ci-readonly"
  }

  assert {
    condition     = !strcontains(local.roles["zot-verify"].policy, "create") && !strcontains(local.roles["zot-verify"].policy, "update")
    error_message = "zot-verify policy must be read-only"
  }

  assert {
    condition     = !strcontains(local.roles["zot-verify"].policy, "ci-readonly")
    error_message = "zot-verify must never grant access to ci-readonly's own credential -- that would be exactly the shared-account pattern this whole effort exists to eliminate"
  }
}

run "zot_verify_service_credential_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "service/k8s-zot/zot-verify/verify-password")
    error_message = "local.secrets must scaffold zot-verify's own dedicated service credential"
  }
}
