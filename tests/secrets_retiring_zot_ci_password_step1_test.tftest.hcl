run "six_orphaned_zot_ci_password_secrets_split_into_retiring_resource" {
  command = plan

  assert {
    condition = length(setsubtract([
      "k8s-hdmi-switch/zot-ci-password",
      "k8s-argocd/zot-ci-password",
      "k8s-graphql-router/zot-ci-password",
      "k8s-lib-ci-rbac/zot-ci-password",
      "k8s-argocd-image-updater/zot-ci-password",
      "k8s-github-runner/zot-ci-password",
    ], local.retiring_secrets)) == 0
    error_message = "all 6 orphaned zot-ci-password keys must be listed in retiring_secrets"
  }

  assert {
    condition = alltrue([
      for k in local.retiring_secrets : contains([for s in local.secrets : "${s.app}/${s.key}"], k)
    ])
    error_message = "every retiring_secrets key must still exist in local.secrets -- required for the moved block to resolve both endpoints"
  }
}
