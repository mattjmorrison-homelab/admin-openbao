# Scaffolds every secret's KV path, blank, using a write-only argument --
# Terraform never stores the value in state and never re-writes it after
# this first apply (data_json_wo only pushes when data_json_wo_version is
# incremented, which nothing here ever does). A value typed into this path
# afterward, in OpenBao directly, is permanently safe from being
# overwritten by any future `tofu apply`.
#
# prevent_destroy guards against accidentally deleting a real secret by
# removing its entry from locals.secrets -- if a key is genuinely retired,
# it needs the two-resource move + prevent_destroy-lift dance documented
# in admin-openbao#27/#28's (and #44/#50/this PR's) history (prevent_destroy
# can't reference each.key directly -- OpenTofu rejects it, since the
# argument must stay evaluable even after an instance drops out of
# for_each).
resource "vault_kv_secret_v2" "secrets" {
  for_each = {
    for s in local.secrets : "${s.app}/${s.key}" => s
    if !contains(local.retiring_secrets, "${s.app}/${s.key}")
  }

  mount                = "kv"
  name                 = "homelab/${each.value.app}/${each.value.key}"
  data_json_wo         = jsonencode({ value = "" })
  data_json_wo_version = 1

  lifecycle {
    prevent_destroy = true
  }
}

# Keys being retired for real -- all 6 are the old shared-ci-user
# homelab/<app>/zot-ci-password paths, now orphaned: every real consumer
# (k8s-hdmi-switch, k8s-argocd, k8s-graphql-router, k8s-lib-ci-rbac,
# k8s-argocd-image-updater, k8s-github-runner) has migrated to its own
# dedicated service/k8s-zot/<name>/<cred> credential, confirmed live, and
# no OpenBao role grants read on any of these 6 paths anymore. This PR:
# a no-op state move, 0 destroyed. A follow-up PR drops these entries
# from local.retiring_secrets (and from the app/keys map in locals.tf)
# entirely to trigger the real destroy -- for k8s-github-runner/
# zot-ci-password specifically, wait for k8s-github-runner#3 (removing
# its last live ExternalSecret reader) to merge and be confirmed live
# first; the other 5 have no such dependency.
locals {
  retiring_secrets = [
    "k8s-hdmi-switch/zot-ci-password",
    "k8s-argocd/zot-ci-password",
    "k8s-graphql-router/zot-ci-password",
    "k8s-lib-ci-rbac/zot-ci-password",
    "k8s-argocd-image-updater/zot-ci-password",
    "k8s-github-runner/zot-ci-password",
  ]
}

resource "vault_kv_secret_v2" "retiring" {
  for_each = {
    for s in local.secrets : "${s.app}/${s.key}" => s
    if contains(local.retiring_secrets, "${s.app}/${s.key}")
  }

  mount                = "kv"
  name                 = "homelab/${each.value.app}/${each.value.key}"
  data_json_wo         = jsonencode({ value = "" })
  data_json_wo_version = 1

  lifecycle {
    prevent_destroy = false
  }
}

moved {
  from = vault_kv_secret_v2.secrets["k8s-hdmi-switch/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["k8s-hdmi-switch/zot-ci-password"]
}

moved {
  from = vault_kv_secret_v2.secrets["k8s-argocd/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["k8s-argocd/zot-ci-password"]
}

moved {
  from = vault_kv_secret_v2.secrets["k8s-graphql-router/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["k8s-graphql-router/zot-ci-password"]
}

moved {
  from = vault_kv_secret_v2.secrets["k8s-lib-ci-rbac/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["k8s-lib-ci-rbac/zot-ci-password"]
}

moved {
  from = vault_kv_secret_v2.secrets["k8s-argocd-image-updater/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["k8s-argocd-image-updater/zot-ci-password"]
}

moved {
  from = vault_kv_secret_v2.secrets["k8s-github-runner/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["k8s-github-runner/zot-ci-password"]
}
