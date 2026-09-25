run "hdmi_switch_discord_roles_grant_both_old_and_new_webhook_paths_during_cutover" {
  command = plan

  assert {
    condition     = strcontains(local.roles["ui-hdmi-switch-discord"].policy, "kv/data/homelab/github-actions/ui-hdmi-switch/webhook-url")
    error_message = "ui-hdmi-switch-discord must grant read/create/update on its new host+client-named webhook path"
  }
  assert {
    condition     = strcontains(local.roles["ui-hdmi-switch-discord"].policy, "kv/data/homelab/ui-hdmi-switch/discord-webhook-url")
    error_message = "ui-hdmi-switch-discord must still keep its old grant during the cutover window -- not repointed live yet"
  }

  assert {
    condition     = strcontains(local.roles["graph-hdmi-switch-discord"].policy, "kv/data/homelab/github-actions/graph-hdmi-switch/webhook-url")
    error_message = "graph-hdmi-switch-discord must grant read/create/update on its new host+client-named webhook path"
  }
  assert {
    condition     = strcontains(local.roles["graph-hdmi-switch-discord"].policy, "kv/data/homelab/graph-hdmi-switch/discord-webhook-url")
    error_message = "graph-hdmi-switch-discord must still keep its old grant during the cutover window -- not repointed live yet"
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
