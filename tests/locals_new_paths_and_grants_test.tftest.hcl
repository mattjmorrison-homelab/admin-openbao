# Prep for the secret-migration-map.md migration: every correctly-prefixed
# new path now exists (scaffolded blank via local.secrets) and every role
# that will eventually read it already grants read on it, alongside the
# still-live old path each currently reads from.

run "new_secrets_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-argocd/zot-ci-password")
    error_message = "k8s-argocd must scaffold zot-ci-password"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-alertmanager/discord-webhook-url")
    error_message = "k8s-alertmanager must scaffold discord-webhook-url"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-alertmanager/downtime-webhook-url")
    error_message = "k8s-alertmanager must scaffold downtime-webhook-url"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-zot/htpasswd")
    error_message = "k8s-zot must scaffold htpasswd"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-argocd-image-updater/zot-ci-password")
    error_message = "k8s-argocd-image-updater must scaffold zot-ci-password"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-cert-manager-config/cloudflare-api-token")
    error_message = "k8s-cert-manager-config must scaffold cloudflare-api-token"
  }
  assert {
    condition = alltrue([
      for key in ["account-tag", "tunnel-id", "tunnel-secret", "cloudflare-api-token", "cf-account-id"] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], "k8s-cloudflare/${key}")
    ])
    error_message = "k8s-cloudflare must scaffold all five keys"
  }
}

run "roles_grant_the_new_paths_too" {
  command = plan

  assert {
    condition     = strcontains(local.roles["alertmanager"].policy, "kv/data/homelab/k8s-alertmanager/*")
    error_message = "alertmanager role must grant k8s-alertmanager/*"
  }
  assert {
    condition     = strcontains(local.roles["zot"].policy, "kv/data/homelab/k8s-zot/*")
    error_message = "zot role must grant k8s-zot/* (not just the exact k8s-zot path)"
  }
  assert {
    condition     = strcontains(local.roles["argocd-image-updater"].policy, "kv/data/homelab/k8s-argocd-image-updater/*")
    error_message = "argocd-image-updater role must grant k8s-argocd-image-updater/*"
  }
  assert {
    condition     = strcontains(local.roles["cert-manager"].policy, "kv/data/homelab/k8s-cert-manager-config/*")
    error_message = "cert-manager role must grant k8s-cert-manager-config/*"
  }
  assert {
    condition     = strcontains(local.roles["cloudflare"].policy, "kv/data/homelab/k8s-cloudflare/*")
    error_message = "cloudflare role must grant k8s-cloudflare/*"
  }
  assert {
    condition     = strcontains(local.roles["cloudflare-bootstrap"].policy, "kv/data/homelab/k8s-cloudflare/*")
    error_message = "cloudflare-bootstrap role must grant k8s-cloudflare/*"
  }
  assert {
    condition     = strcontains(local.roles["argocd-webhook"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-webhook role must grant k8s-argocd/* (github-webhook-secret lives there)"
  }
  assert {
    condition     = strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-repo-creds-oci role must grant k8s-argocd/* (zot-ci-password lives there)"
  }
}
