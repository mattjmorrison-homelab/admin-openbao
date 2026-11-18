# admin-discord#18 added a CI check validating every webhook's target
# OpenBao path has this grant, before merge. It caught two legacy paths --
# populated by hand long ago, never through this write-back mechanism, but
# now intentionally included so the mechanism covers them going forward --
# that were missing it: k8s-alertmanager and k8s-argocd's discord-webhook-url.

run "admin_discord_webhooks_role_writes_legacy_alertmanager_and_argocd_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/k8s-alertmanager/discord-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-alertmanager's legacy discord webhook path"
  }

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/k8s-argocd/discord-webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on k8s-argocd's legacy discord webhook path"
  }

  assert {
    condition = alltrue([
      for p in ["ui-hdmi-switch", "graph-hdmi-switch", "app-backstage"] :
      strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/${p}/webhook-url")
    ])
    error_message = "admin-discord-webhooks must keep its existing write grants for ui-hdmi-switch, graph-hdmi-switch, and app-backstage unchanged"
  }
}
