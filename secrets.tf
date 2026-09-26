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
# in admin-openbao#27/#28's (and #44/#50/#52/#63/#64/this PR's) history
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

# Keys being retired for real -- both are the old shared-webhook
# host+client-named homelab/github-actions/<repo>/webhook-url paths,
# now orphaned: admin-discord stopped sharing one Discord webhook
# object across repos and instead pushes each consumer's own dedicated
# webhook URL straight into service/admin-discord/<repo>/webhook-url
# (admin-discord#9, admin-openbao#66), and both hdmi-switch-discord
# roles narrowed off this old path (admin-openbao#67). This PR: a
# no-op state move, 0 destroyed. A follow-up PR drops these entries
# from local.retiring_secrets (and the app/keys map in locals.tf)
# entirely to trigger the real destroy.
locals {
  retiring_secrets = [
    "github-actions/ui-hdmi-switch/webhook-url",
    "github-actions/graph-hdmi-switch/webhook-url",
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
  from = vault_kv_secret_v2.secrets["github-actions/ui-hdmi-switch/webhook-url"]
  to   = vault_kv_secret_v2.retiring["github-actions/ui-hdmi-switch/webhook-url"]
}

moved {
  from = vault_kv_secret_v2.secrets["github-actions/graph-hdmi-switch/webhook-url"]
  to   = vault_kv_secret_v2.retiring["github-actions/graph-hdmi-switch/webhook-url"]
}
