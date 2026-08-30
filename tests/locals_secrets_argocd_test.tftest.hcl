run "secrets_use_renamed_k8s_argocd_app_prefix" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : s.app], "k8s-argocd")
    error_message = "local.secrets should have an entry with app = \"k8s-argocd\" (the repo was renamed from homelab-argocd to k8s-argocd)"
  }

  assert {
    condition     = contains([for s in local.secrets : s.key if s.app == "k8s-argocd"], "discord-webhook-url")
    error_message = "local.secrets app = \"k8s-argocd\" should include key \"discord-webhook-url\""
  }

  assert {
    condition     = contains([for s in local.secrets : s.key if s.app == "k8s-argocd"], "github-webhook-secret")
    error_message = "local.secrets app = \"k8s-argocd\" should include key \"github-webhook-secret\""
  }

  assert {
    condition     = !contains([for s in local.secrets : s.app], "homelab-argocd")
    error_message = "local.secrets should no longer have an entry with app = \"homelab-argocd\" (repo was renamed to k8s-argocd)"
  }
}
