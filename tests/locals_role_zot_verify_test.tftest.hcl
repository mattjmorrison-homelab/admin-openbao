run "zot_verify_role_is_read_only_and_scoped_to_ci_readonly_password" {
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
    condition     = strcontains(local.roles["zot-verify"].policy, "kv/data/homelab/k8s-zot/ci-readonly-password")
    error_message = "zot-verify policy must grant read on exactly k8s-zot/ci-readonly-password"
  }

  assert {
    condition     = !strcontains(local.roles["zot-verify"].policy, "create") && !strcontains(local.roles["zot-verify"].policy, "update")
    error_message = "zot-verify policy must be read-only"
  }

  assert {
    condition     = !strcontains(local.roles["zot-verify"].policy, "htpasswd")
    error_message = "zot-verify must not be able to read the htpasswd blob itself -- only the separate plaintext test credential"
  }
}

run "ci_readonly_password_scaffolded_alongside_htpasswd" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-zot/ci-readonly-password")
    error_message = "local.secrets must scaffold k8s-zot/ci-readonly-password"
  }
}
