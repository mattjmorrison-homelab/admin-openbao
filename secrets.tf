# Scaffolds every secret's KV path, blank, using a write-only argument --
# Terraform never stores the value in state and never re-writes it after
# this first apply (data_json_wo only pushes when data_json_wo_version is
# incremented, which nothing here ever does). A value typed into this path
# afterward, in OpenBao directly, is permanently safe from being
# overwritten by any future `tofu apply`.
#
# prevent_destroy guards against accidentally deleting a real secret by
# removing its entry from locals.secrets -- if a key is genuinely retired,
# delete it in OpenBao first, then remove it here.
#
# prevent_destroy can't reference each.key (OpenTofu rejects it: the
# argument must stay evaluable even for an instance that has already
# dropped out of for_each, which is exactly the moment a real destroy
# would happen). So retiring a key is a two-resource move instead: a
# `moved` block relocates it from this protected resource into
# `retiring` below (a no-op on the real infrastructure -- same mount/
# name/data, just a different Terraform address), and only once it's
# living under `retiring` can its locals.secrets entry actually be
# removed to delete it for real.
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

# Confirmed-orphaned keys (see local.retiring_secrets), parked here with
# prevent_destroy off so a follow-up PR can remove their locals.secrets
# entry and have `tofu apply` actually delete them. Until that follow-up
# PR, this resource is otherwise identical to `secrets` above -- nothing
# about the real KV path changes by living here instead.
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

# One `moved` block per retiring key -- without these, OpenTofu would
# plan to destroy each key under the old `secrets` address (blocked by
# prevent_destroy) and recreate it under `retiring`, instead of
# recognizing it as the same object. Safe to delete these once every
# retiring key has actually been removed from locals.secrets and its
# `retiring` instance no longer exists.
moved {
  from = vault_kv_secret_v2.secrets["service/k8s-zot/k8s-garage/pull-helm-libs"]
  to   = vault_kv_secret_v2.retiring["service/k8s-zot/k8s-garage/pull-helm-libs"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-alertmanager/discord-webhook-url"]
  to   = vault_kv_secret_v2.retiring["homelab-alertmanager/discord-webhook-url"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-zot/htpasswd"]
  to   = vault_kv_secret_v2.retiring["homelab-zot/htpasswd"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-argocd-image-updater/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["homelab-argocd-image-updater/zot-ci-password"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-cert-manager-config/cloudflare-api-token"]
  to   = vault_kv_secret_v2.retiring["homelab-cert-manager-config/cloudflare-api-token"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-argocd/discord-webhook-url"]
  to   = vault_kv_secret_v2.retiring["homelab-argocd/discord-webhook-url"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-argocd/github-webhook-secret"]
  to   = vault_kv_secret_v2.retiring["homelab-argocd/github-webhook-secret"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-prometheus/woodpecker-prometheus-auth-token"]
  to   = vault_kv_secret_v2.retiring["homelab-prometheus/woodpecker-prometheus-auth-token"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-woodpecker/github-client"]
  to   = vault_kv_secret_v2.retiring["homelab-woodpecker/github-client"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-woodpecker/github-secret"]
  to   = vault_kv_secret_v2.retiring["homelab-woodpecker/github-secret"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-woodpecker/agent-secret"]
  to   = vault_kv_secret_v2.retiring["homelab-woodpecker/agent-secret"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-woodpecker/vault-token"]
  to   = vault_kv_secret_v2.retiring["homelab-woodpecker/vault-token"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-woodpecker/prometheus-auth-token"]
  to   = vault_kv_secret_v2.retiring["homelab-woodpecker/prometheus-auth-token"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-woodpecker/zot-ci-password"]
  to   = vault_kv_secret_v2.retiring["homelab-woodpecker/zot-ci-password"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-cloudflare/account-tag"]
  to   = vault_kv_secret_v2.retiring["homelab-cloudflare/account-tag"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-cloudflare/tunnel-id"]
  to   = vault_kv_secret_v2.retiring["homelab-cloudflare/tunnel-id"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-cloudflare/tunnel-secret"]
  to   = vault_kv_secret_v2.retiring["homelab-cloudflare/tunnel-secret"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-cloudflare/cloudflare-api-token"]
  to   = vault_kv_secret_v2.retiring["homelab-cloudflare/cloudflare-api-token"]
}
moved {
  from = vault_kv_secret_v2.secrets["homelab-cloudflare/cf-account-id"]
  to   = vault_kv_secret_v2.retiring["homelab-cloudflare/cf-account-id"]
}
