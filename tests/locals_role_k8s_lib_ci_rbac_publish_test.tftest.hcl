run "k8s_lib_ci_rbac_publish_role_reads_its_real_per_consumer_zot_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["k8s-lib-ci-rbac-publish"].policy, "kv/data/homelab/service/k8s-zot/k8s-lib-ci-rbac/zot-publish")
    error_message = "k8s-lib-ci-rbac-publish must grant read on its own dedicated Zot publish credential"
  }

  assert {
    condition     = !strcontains(local.roles["k8s-lib-ci-rbac-publish"].policy, "kv/data/homelab/k8s-lib-ci-rbac/*")
    error_message = "k8s-lib-ci-rbac-publish must not grant the old k8s-lib-ci-rbac/* wildcard -- that path was never populated, and this role only ever needs the one real Zot credential"
  }

  assert {
    condition     = !strcontains(local.roles["k8s-lib-ci-rbac-publish"].policy, "create") && !strcontains(local.roles["k8s-lib-ci-rbac-publish"].policy, "update")
    error_message = "k8s-lib-ci-rbac-publish must be read-only -- it only ever reads this to log into the registry, never writes it"
  }
}
