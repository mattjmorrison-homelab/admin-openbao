run "zot_bootstrap_role_writes_its_own_service_subtree_only" {
  command = plan

  assert {
    condition     = local.roles["zot-bootstrap"].namespace == "zot"
    error_message = "zot-bootstrap role must bind in the zot namespace"
  }

  assert {
    condition     = local.roles["zot-bootstrap"].service_account == "zot-bootstrap"
    error_message = "zot-bootstrap role must bind to the zot-bootstrap ServiceAccount, not the zot app's own read-only one"
  }

  assert {
    condition     = strcontains(local.roles["zot-bootstrap"].policy, "kv/data/homelab/service/k8s-zot/*")
    error_message = "zot-bootstrap policy must grant a wildcard write on its own service/k8s-zot/* subtree, covering every consumer"
  }

  assert {
    condition     = !strcontains(local.roles["zot-bootstrap"].policy, "service/k8s-garage")
    error_message = "zot-bootstrap policy must not name a specific consumer path directly -- the wildcard already covers it"
  }
}
