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

# Additive step of migrating k8s-argocd's Discord webhook onto the standard
# service/admin-discord/<consumer>/<cred> convention (admin-discord#18).
# argocd-notifications gains read on the new exact key alongside its
# still-live old exact key -- the old grant is dropped later, once
# k8s-argocd's ExternalSecrets are repointed and confirmed.
run "argocd_notifications_also_reads_new_admin_discord_path" {
  command = plan

  assert {
    condition     = strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/service/admin-discord/k8s-argocd/discord-webhook-url")
    error_message = "argocd-notifications must grant read on the new service/admin-discord/k8s-argocd/discord-webhook-url path"
  }

  assert {
    condition     = strcontains(local.roles["argocd-notifications"].policy, "kv/data/homelab/k8s-argocd/discord-webhook-url")
    error_message = "argocd-notifications must keep its existing read grant on the old k8s-argocd/discord-webhook-url path unchanged"
  }
}
