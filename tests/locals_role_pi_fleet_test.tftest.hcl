run "pi_fleet_policy_scoped_to_exactly_its_own_sign_path" {
  command = plan

  assert {
    condition     = strcontains(local.roles["pi-fleet"].policy, "ssh/sign/pi-fleet")
    error_message = "pi-fleet policy must grant its own ssh/sign/pi-fleet path"
  }

  assert {
    condition     = !strcontains(local.roles["pi-fleet"].policy, "ssh/sign/*")
    error_message = "pi-fleet policy must not use a wildcard -- scoped to exactly its own role"
  }

  assert {
    condition     = local.roles["pi-fleet"].kubernetes_auth == false
    error_message = "pi-fleet authenticates via GitHub Actions OIDC only, not Kubernetes auth"
  }
}
