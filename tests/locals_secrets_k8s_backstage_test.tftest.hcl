# Scaffolds the GitHub App credentials for k8s-backstage ahead of the app
# itself existing -- no role yet, since there's no namespace/ServiceAccount
# to bind until Backstage is actually deployed.

run "k8s_backstage_github_app_secrets_scaffolded" {
  command = plan

  assert {
    condition = alltrue([
      for key in ["github-app-id", "github-app-client-id", "github-app-client-secret", "github-app-private-key"] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-backstage/${key}")
    ])
    error_message = "k8s-backstage must scaffold all four GitHub App credential keys"
  }
}
