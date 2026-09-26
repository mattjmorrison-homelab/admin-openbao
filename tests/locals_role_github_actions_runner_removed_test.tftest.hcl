# The old shared tofu-state role every Terraform repo used to read from
# before each repo migrated onto its own dedicated per-repo bucket/role
# (admin-discord-tofu-state, admin-github-tofu-state, admin-cloudflare-tofu-state,
# admin-openbao-tofu-state). Confirmed zero remaining consumers org-wide --
# every fetch-credentials call in every repo's workflows now passes its own
# role explicitly -- so the role is removed outright rather than left unused.

run "github_actions_runner_role_no_longer_exists" {
  command = plan

  assert {
    condition     = !contains(keys(local.roles), "github-actions-runner")
    error_message = "local.roles must not include \"github-actions-runner\" -- fully replaced by per-repo tofu-state roles, zero remaining consumers"
  }
}
