run "two_orphaned_hdmi_switch_github_actions_webhook_secrets_split_into_retiring_resource" {
  command = plan

  assert {
    condition = length(setsubtract([
      "github-actions/ui-hdmi-switch/webhook-url",
      "github-actions/graph-hdmi-switch/webhook-url",
    ], local.retiring_secrets)) == 0
    error_message = "both orphaned github-actions/<repo>/webhook-url keys must be listed in retiring_secrets"
  }

  assert {
    condition = alltrue([
      for k in local.retiring_secrets : contains([for s in local.secrets : "${s.app}/${s.key}"], k)
    ])
    error_message = "every retiring_secrets key must still exist in local.secrets -- required for the moved block to resolve both endpoints"
  }
}
