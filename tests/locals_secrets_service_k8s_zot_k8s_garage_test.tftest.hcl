run "service_secrets_include_k8s_zot_k8s_garage_pull_helm_libs" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : s.app], "service/k8s-zot/k8s-garage")
    error_message = "local.secrets should have an entry with app = \"service/k8s-zot/k8s-garage\""
  }

  assert {
    condition     = contains([for s in local.secrets : s.key if s.app == "service/k8s-zot/k8s-garage"], "pull-helm-libs")
    error_message = "local.secrets app = \"service/k8s-zot/k8s-garage\" should include key \"pull-helm-libs\""
  }
}
