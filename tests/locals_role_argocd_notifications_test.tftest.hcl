run "argocd_notifications_policy_grants_only_new_argocd_path" {
  command = plan

  assert {
    condition     = !strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/homelab-argocd/*")
    error_message = "argocd-notifications policy should no longer grant the old path kv/data/homelab/homelab-argocd/* (k8s-argocd's ExternalSecrets have repointed and been confirmed)"
  }

  assert {
    condition     = strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-notifications policy must grant the new path kv/data/homelab/k8s-argocd/*"
  }
}
