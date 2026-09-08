run "argocd_notifications_policy_grants_only_its_own_exact_key" {
  command = plan

  assert {
    condition     = !strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/homelab-argocd/*")
    error_message = "argocd-notifications policy should no longer grant the old path kv/data/homelab/homelab-argocd/* (k8s-argocd's ExternalSecrets have repointed and been confirmed)"
  }

  assert {
    condition     = strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/k8s-argocd/discord-webhook-url")
    error_message = "argocd-notifications policy must grant its own exact key, k8s-argocd/discord-webhook-url"
  }

  assert {
    condition     = !strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-notifications policy must not grant the k8s-argocd/* wildcard -- it should only read its own key, not github-webhook-secret or zot-ci-password too"
  }
}
