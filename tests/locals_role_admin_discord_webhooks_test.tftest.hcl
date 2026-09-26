run "admin_discord_webhooks_role_writes_only_the_two_consumer_paths" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/ui-hdmi-switch/webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on ui-hdmi-switch's dedicated webhook path"
  }
  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/graph-hdmi-switch/webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on graph-hdmi-switch's dedicated webhook path"
  }
  assert {
    condition     = local.roles["admin-discord-webhooks"].service_account == "github-runner-workload"
    error_message = "admin-discord-webhooks must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }
}

run "hdmi_switch_discord_roles_grant_read_only_on_the_new_admin_discord_owned_path" {
  command = plan

  assert {
    condition     = strcontains(local.roles["ui-hdmi-switch-discord"].policy, "kv/data/homelab/service/admin-discord/ui-hdmi-switch/webhook-url")
    error_message = "ui-hdmi-switch-discord must grant read on the new admin-discord-owned webhook path"
  }
  assert {
    condition     = !strcontains(local.roles["ui-hdmi-switch-discord"].policy, "kv/data/homelab/github-actions/ui-hdmi-switch/webhook-url")
    error_message = "ui-hdmi-switch-discord must no longer grant anything on the old github-actions/webhook-url path -- narrowed to read-only on the new path"
  }
  assert {
    condition     = strcontains(local.roles["graph-hdmi-switch-discord"].policy, "kv/data/homelab/service/admin-discord/graph-hdmi-switch/webhook-url")
    error_message = "graph-hdmi-switch-discord must grant read on the new admin-discord-owned webhook path"
  }
  assert {
    condition     = !strcontains(local.roles["graph-hdmi-switch-discord"].policy, "kv/data/homelab/github-actions/graph-hdmi-switch/webhook-url")
    error_message = "graph-hdmi-switch-discord must no longer grant anything on the old github-actions/webhook-url path -- narrowed to read-only on the new path"
  }
}

run "admin_discord_webhook_service_credentials_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "service/admin-discord/ui-hdmi-switch/webhook-url")
    error_message = "service/admin-discord/ui-hdmi-switch/webhook-url must be scaffolded"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "service/admin-discord/graph-hdmi-switch/webhook-url")
    error_message = "service/admin-discord/graph-hdmi-switch/webhook-url must be scaffolded"
  }
}
