# Additive step of migrating k8s-alertmanager's and k8s-argocd's Discord
# webhooks from their old self-owned OpenBao paths onto the standard
# service/admin-discord/<consumer>/<cred> convention (admin-discord#18).
# admin-discord's CI write-back needs create/update on the new paths
# alongside the still-live old paths -- old grants/paths are dropped later,
# once both consumers are repointed and confirmed.

run "admin_discord_webhooks_role_writes_k8s_alertmanager_and_k8s_argocd_new_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/k8s-alertmanager/discord-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-alertmanager's new discord-webhook-url path"
  }

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/k8s-alertmanager/downtime-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-alertmanager's new downtime-webhook-url path"
  }

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/k8s-argocd/discord-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-argocd's new discord-webhook-url path"
  }

  assert {
    condition = alltrue([
      for p in ["ui-hdmi-switch", "graph-hdmi-switch", "app-backstage"] :
      strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/${p}/webhook-url")
    ])
    error_message = "admin-discord-webhooks must keep its existing write grants for ui-hdmi-switch, graph-hdmi-switch, and app-backstage unchanged"
  }

  assert {
    condition = alltrue([
      for p in ["confirmed-webhook-url", "suspicious-webhook-url"] :
      strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/k8s-ad-reporter/${p}")
    ])
    error_message = "admin-discord-webhooks must keep its existing write grants for k8s-ad-reporter unchanged"
  }
}
