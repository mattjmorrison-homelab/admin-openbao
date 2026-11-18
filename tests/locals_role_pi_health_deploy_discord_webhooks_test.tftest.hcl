# pi-health has no in-cluster SecretStore of its own -- a separate,
# parallel change in admin-discord writes its uptime/downtime webhook
# URLs to these exact paths, same convention as its other consumers
# (service/admin-discord/<consumer>/<cred-name>).

run "pi_health_deploy_can_read_its_discord_webhooks" {
  command = plan

  assert {
    condition     = strcontains(local.roles["pi-health-deploy"].policy, "kv/data/homelab/service/admin-discord/pi-health/uptime-webhook-url")
    error_message = "pi-health-deploy must grant read on its uptime webhook URL"
  }

  assert {
    condition     = strcontains(local.roles["pi-health-deploy"].policy, "kv/data/homelab/service/admin-discord/pi-health/downtime-webhook-url")
    error_message = "pi-health-deploy must grant read on its downtime webhook URL"
  }

  assert {
    condition     = strcontains(local.roles["pi-health-deploy"].policy, "kv/data/homelab/pi-health/ssh-private-key")
    error_message = "pi-health-deploy must still grant read on its existing ssh-private-key path"
  }

  assert {
    condition     = local.roles["pi-health-deploy"].namespace == "github-runner" && local.roles["pi-health-deploy"].service_account == "github-runner-workload"
    error_message = "pi-health-deploy must keep binding to the shared github-runner-workload identity, unchanged"
  }
}
