# admin-discord's CI has write-back steps for k8s-ad-reporter's two Discord
# webhook URLs (confirmed-webhook-url, suspicious-webhook-url) that were
# missing their grants here -- those writes have been 403ing since before
# this was caught, the same way app-backstage's and pi-health's did before
# they were added.

run "admin_discord_webhooks_role_writes_k8s_ad_reporter_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/k8s-ad-reporter/confirmed-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-ad-reporter's confirmed webhook path"
  }

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/k8s-ad-reporter/suspicious-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-ad-reporter's suspicious webhook path"
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
      for p in ["uptime-webhook-url", "downtime-webhook-url"] :
      strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/pi-health/${p}")
    ])
    error_message = "admin-discord-webhooks must keep its existing write grants for pi-health unchanged"
  }
}
