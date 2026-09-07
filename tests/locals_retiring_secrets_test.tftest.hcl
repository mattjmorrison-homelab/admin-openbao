run "retiring_secrets_lists_exactly_the_confirmed_orphans" {
  command = plan

  assert {
    condition = length(local.retiring_secrets) == 19
    error_message = "retiring_secrets should list exactly the 19 confirmed-orphaned app/key entries"
  }

  assert {
    condition = alltrue([
      for entry in [
        "service/k8s-zot/k8s-garage/pull-helm-libs",
        "homelab-alertmanager/discord-webhook-url",
        "homelab-zot/htpasswd",
        "homelab-argocd-image-updater/zot-ci-password",
        "homelab-cert-manager-config/cloudflare-api-token",
        "homelab-argocd/discord-webhook-url",
        "homelab-argocd/github-webhook-secret",
        "homelab-prometheus/woodpecker-prometheus-auth-token",
        "homelab-woodpecker/github-client",
        "homelab-woodpecker/github-secret",
        "homelab-woodpecker/agent-secret",
        "homelab-woodpecker/vault-token",
        "homelab-woodpecker/prometheus-auth-token",
        "homelab-woodpecker/zot-ci-password",
        "homelab-cloudflare/account-tag",
        "homelab-cloudflare/tunnel-id",
        "homelab-cloudflare/tunnel-secret",
        "homelab-cloudflare/cloudflare-api-token",
        "homelab-cloudflare/cf-account-id",
      ] : contains(local.retiring_secrets, entry)
    ])
    error_message = "retiring_secrets is missing one of the confirmed-orphaned entries"
  }

  assert {
    condition     = !contains(local.retiring_secrets, "admin-github/tofu-state-access-key-id")
    error_message = "admin-github/tofu-state-access-key-id is still live (read by actions-tofu/fetch-credentials) -- must not be retired"
  }

  assert {
    condition     = !contains(local.retiring_secrets, "pi/pi1/private-key")
    error_message = "pi/pi1/private-key is still live (read by pi-provision's workflows) -- must not be retired"
  }

  assert {
    condition     = !contains(local.retiring_secrets, "k8s-graphql-router/zot-ci-password")
    error_message = "k8s-graphql-router/zot-ci-password is not yet migrated (its ExternalSecret still reads the old homelab/graphql-router path), not orphaned -- must not be retired"
  }
}
