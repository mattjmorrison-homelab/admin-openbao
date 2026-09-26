run "two_orphaned_hdmi_switch_github_actions_webhook_secrets_removed_for_real" {
  command = plan

  assert {
    condition = length(setintersection([for s in local.secrets : "${s.app}/${s.key}"], [
      "github-actions/ui-hdmi-switch/webhook-url",
      "github-actions/graph-hdmi-switch/webhook-url",
    ])) == 0
    error_message = "both orphaned github-actions/<repo>/webhook-url keys must be fully removed from local.secrets -- both repos migrated to their own admin-discord-owned webhook credential"
  }
}
