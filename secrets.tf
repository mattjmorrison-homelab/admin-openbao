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
# in admin-openbao#27/#28's history (prevent_destroy can't reference
# each.key directly -- OpenTofu rejects it, since the argument must stay
# evaluable even after an instance drops out of for_each). No key is
# currently mid-retirement, so there's only the one resource right now.
resource "vault_kv_secret_v2" "secrets" {
  for_each = {
    for s in local.secrets : "${s.app}/${s.key}" => s
  }

  mount                = "kv"
  name                 = "homelab/${each.value.app}/${each.value.key}"
  data_json_wo         = jsonencode({ value = "" })
  data_json_wo_version = 1

  lifecycle {
    prevent_destroy = true
  }
}
