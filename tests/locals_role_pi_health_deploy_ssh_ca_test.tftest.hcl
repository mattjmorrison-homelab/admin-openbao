run "pi_health_deploy_can_sign_against_the_pi_fleet_ssh_ca" {
  command = plan

  assert {
    condition     = strcontains(local.roles["pi-health-deploy"].policy, "ssh/sign/pi-fleet")
    error_message = "pi-health-deploy must grant create/update on ssh/sign/pi-fleet"
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
