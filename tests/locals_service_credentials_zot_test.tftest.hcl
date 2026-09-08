run "zot_service_credentials_scaffold_all_9_real_consumers" {
  command = plan

  assert {
    condition = alltrue([
      for consumer_cred in [
        "k8s-garage/pull-helm-libs",
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
    error_message = "local.secrets must scaffold all 9 real k8s-zot service-credential consumers"
  }
}
