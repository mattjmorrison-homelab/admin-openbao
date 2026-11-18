# admin-discord#17 adds write-back steps for pi-health's two Discord
# webhook URLs -- without these grants that write-back 403s the same way
# app-backstage's did before it was added here.

run "admin_discord_webhooks_role_writes_pi_health_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/pi-health/uptime-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on pi-health's uptime webhook path"
  }

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/pi-health/downtime-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on pi-health's downtime webhook path"
  }

  assert {
    condition = alltrue([
      for p in ["ui-hdmi-switch", "graph-hdmi-switch", "app-backstage"] :
      strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/${p}/webhook-url")
    ])
    error_message = "admin-discord-webhooks must keep its existing write grants for ui-hdmi-switch, graph-hdmi-switch, and app-backstage unchanged"
  }
}
