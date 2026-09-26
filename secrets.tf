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
# in admin-openbao#27/#28's (and #44/#50/#52/#63/this PR's) history
# (prevent_destroy can't reference each.key directly -- OpenTofu rejects
# it, since the argument must stay evaluable even after an instance
# drops out of for_each).
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

# Keys being retired for real -- both are the old client-only-named
# homelab/<repo>/discord-webhook-url paths, now orphaned: both
# ui-hdmi-switch and graph-hdmi-switch have migrated to their own
# host+client-named service/github-actions/<repo>/webhook-url
# credential (#40), confirmed live via real CI runs, and their roles
# narrowed (admin-openbao#63). This PR: a no-op state move, 0
# destroyed. A follow-up PR drops these entries from
# local.retiring_secrets (and the app/keys map in locals.tf) entirely
# to trigger the real destroy.
locals {
  retiring_secrets = [
    "ui-hdmi-switch/discord-webhook-url",
    "graph-hdmi-switch/discord-webhook-url",
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
  from = vault_kv_secret_v2.secrets["ui-hdmi-switch/discord-webhook-url"]
  to   = vault_kv_secret_v2.retiring["ui-hdmi-switch/discord-webhook-url"]
}

moved {
  from = vault_kv_secret_v2.secrets["graph-hdmi-switch/discord-webhook-url"]
  to   = vault_kv_secret_v2.retiring["graph-hdmi-switch/discord-webhook-url"]
}
