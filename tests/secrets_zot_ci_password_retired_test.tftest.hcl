run "six_orphaned_zot_ci_password_secrets_removed_for_real" {
  command = plan

  assert {
    condition = length(setintersection([for s in local.secrets : "${s.app}/${s.key}"], [
      "k8s-hdmi-switch/zot-ci-password",
      "k8s-argocd/zot-ci-password",
      "k8s-graphql-router/zot-ci-password",
      "k8s-lib-ci-rbac/zot-ci-password",
      "k8s-argocd-image-updater/zot-ci-password",
      "k8s-github-runner/zot-ci-password",
    ])) == 0
    error_message = "all 6 orphaned zot-ci-password keys must be fully removed from local.secrets -- every real consumer migrated to its own service/k8s-zot/<name>/<cred> credential"
  }
}
