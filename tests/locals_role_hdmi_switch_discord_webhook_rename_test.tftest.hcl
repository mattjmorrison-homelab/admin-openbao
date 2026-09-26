run "hdmi_switch_discord_roles_scoped_to_only_the_new_host_client_named_webhook_path" {
  command = plan

  assert {
    condition     = !strcontains(local.roles["ui-hdmi-switch-discord"].policy, "kv/data/homelab/github-actions/ui-hdmi-switch/webhook-url")
    error_message = "ui-hdmi-switch-discord's old github-actions/webhook-url grant must be gone -- admin-discord owns writing this value now"
  }
  assert {
    condition     = !strcontains(local.roles["ui-hdmi-switch-discord"].policy, "kv/data/homelab/ui-hdmi-switch/discord-webhook-url")
    error_message = "ui-hdmi-switch-discord's old discord-webhook-url grant must be gone -- migration confirmed live"
  }

  assert {
    condition     = !strcontains(local.roles["graph-hdmi-switch-discord"].policy, "kv/data/homelab/github-actions/graph-hdmi-switch/webhook-url")
    error_message = "graph-hdmi-switch-discord's old github-actions/webhook-url grant must be gone -- admin-discord owns writing this value now"
  }
  assert {
    condition     = !strcontains(local.roles["graph-hdmi-switch-discord"].policy, "kv/data/homelab/graph-hdmi-switch/discord-webhook-url")
    error_message = "graph-hdmi-switch-discord's old discord-webhook-url grant must be gone -- migration confirmed live"
  }
}

run "hdmi_switch_new_host_client_secrets_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "github-actions/ui-hdmi-switch/webhook-url")
    error_message = "github-actions/ui-hdmi-switch/webhook-url must be scaffolded"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "github-actions/graph-hdmi-switch/webhook-url")
    error_message = "github-actions/graph-hdmi-switch/webhook-url must be scaffolded"
  }
}
