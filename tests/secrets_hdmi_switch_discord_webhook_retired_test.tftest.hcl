run "two_orphaned_hdmi_switch_discord_webhook_secrets_removed_for_real" {
  command = plan

  assert {
    condition = length(setintersection([for s in local.secrets : "${s.app}/${s.key}"], [
      "ui-hdmi-switch/discord-webhook-url",
      "graph-hdmi-switch/discord-webhook-url",
    ])) == 0
    error_message = "both orphaned discord-webhook-url keys must be fully removed from local.secrets -- both repos migrated to their own host+client-named credential"
  }
}
