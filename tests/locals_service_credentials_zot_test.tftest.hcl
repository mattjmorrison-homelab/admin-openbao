run "zot_service_credentials_scaffold_all_8_real_consumers" {
  command = plan

  assert {
    condition = alltrue([
      for consumer_cred in [
        "k8s-graphql-router/zot-pull",
        "k8s-hdmi-switch/zot-pull",
        "k8s-argocd/zot-pull",
        "k8s-argocd-image-updater/zot-pull",
        "k8s-lib-ci-rbac/zot-publish",
        "graph-router/zot-publish",
        "graph-hdmi-switch/zot-publish",
        "ui-hdmi-switch/zot-publish",
      ] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], "service/k8s-zot/${consumer_cred}")
    ])
    error_message = "local.secrets must scaffold all 8 real k8s-zot service-credential consumers"
  }

  assert {
    condition     = !contains([for s in local.secrets : "${s.app}/${s.key}"], "service/k8s-zot/k8s-garage/pull-helm-libs")
    error_message = "k8s-garage/pull-helm-libs was confirmed unused (no Chart.yaml dependency, no manifest, no workflow references it) and retired -- must not be scaffolded anymore"
  }
}
