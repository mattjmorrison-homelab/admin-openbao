# Woodpecker is being decommissioned outright -- everything's migrated
# onto GitHub Actions. These roles no longer have a live pod to bind to.

run "woodpecker_roles_no_longer_exist" {
  command = plan

  assert {
    condition     = !contains(keys(local.roles), "woodpecker")
    error_message = "local.roles must not include \"woodpecker\" -- it's being decommissioned"
  }

  assert {
    condition     = !contains(keys(local.roles), "woodpecker-bootstrap")
    error_message = "local.roles must not include \"woodpecker-bootstrap\" -- it's being decommissioned"
  }
}
