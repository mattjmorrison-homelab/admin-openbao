run "argocd_notifications_policy_grants_old_and_new_argocd_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/homelab-argocd/*")
    error_message = "argocd-notifications policy must still grant the old path kv/data/homelab/homelab-argocd/* (repo secret data has not migrated yet)"
  }

  assert {
    condition     = strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-notifications policy must also grant the new path kv/data/homelab/k8s-argocd/* (repo was renamed from homelab-argocd to k8s-argocd)"
  }
}
