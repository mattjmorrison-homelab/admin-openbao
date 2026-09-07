run "argocd_webhook_policy_grants_only_its_own_exact_key" {
  command = plan

  assert {
    condition     = strcontains(local.roles["argocd-webhook"].policy, "kv/data/homelab/k8s-argocd/github-webhook-secret")
    error_message = "argocd-webhook policy must grant its own exact key, k8s-argocd/github-webhook-secret"
  }

  assert {
    condition     = !strcontains(local.roles["argocd-webhook"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-webhook policy must not grant the k8s-argocd/* wildcard -- it should only read its own key, not discord-webhook-url or zot-ci-password too"
  }
}
