run "k8s_garage_pull_helm_libs_role_is_read_only_and_scoped_to_one_cred" {
  command = plan

  assert {
    condition     = local.roles["k8s-garage-pull-helm-libs"].namespace == "github-runner"
    error_message = "k8s-garage-pull-helm-libs role must bind in the github-runner namespace, same as every other CI-fetch role"
  }

  assert {
    condition     = local.roles["k8s-garage-pull-helm-libs"].service_account == "github-runner-workload"
    error_message = "k8s-garage-pull-helm-libs role must bind to the shared github-runner-workload identity"
  }

  assert {
    condition     = strcontains(local.roles["k8s-garage-pull-helm-libs"].policy, "kv/data/homelab/service/k8s-zot/k8s-garage/pull-helm-libs")
    error_message = "k8s-garage-pull-helm-libs policy must grant read on its exact credential path"
  }

  assert {
    condition     = !strcontains(local.roles["k8s-garage-pull-helm-libs"].policy, "create") && !strcontains(local.roles["k8s-garage-pull-helm-libs"].policy, "update")
    error_message = "k8s-garage-pull-helm-libs policy must be read-only -- k8s-garage is the consumer, not the provider"
  }
}
