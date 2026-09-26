run "two_orphaned_hdmi_switch_discord_webhook_secrets_split_into_retiring_resource" {
  command = plan

  assert {
    condition = length(setsubtract([
      "ui-hdmi-switch/discord-webhook-url",
      "graph-hdmi-switch/discord-webhook-url",
    ], local.retiring_secrets)) == 0
    error_message = "both orphaned discord-webhook-url keys must be listed in retiring_secrets"
  }

  assert {
    condition = alltrue([
      for k in local.retiring_secrets : contains([for s in local.secrets : "${s.app}/${s.key}"], k)
    ])
    error_message = "every retiring_secrets key must still exist in local.secrets -- required for the moved block to resolve both endpoints"
  }
}
