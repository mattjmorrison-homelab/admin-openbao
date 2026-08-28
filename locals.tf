# The complete inventory of Kubernetes auth roles this homelab actually
# uses, and what each one can read/write. Captured directly from every
# SecretStore, ExternalSecret, and bootstrap script across every repo as of
# 2026-08-21 -- this is the single place that answers "what secrets exist
# and who can read them" without reverse-engineering it from application
# code again.
#
# KV path app-prefixes in the NEW paths match each secret's owning repo's
# exact current name (checked against `gh repo list`), not an informal
# short name -- grepping a repo name should always find its secrets with
# no translation.
#
# Every policy here grants BOTH the old (currently live, still in use) and
# new (target) paths during the migration window -- Vault policy writes
# fully replace the previous document, so applying this without the old
# grant would immediately break every app's secret refresh, since nothing
# has actually migrated to the new paths yet. Drop each old-path block
# only once that specific app's ExternalSecrets have been repointed and
# verified against the new path.
locals {
  roles = {
    alertmanager = {
      namespace       = "monitoring"
      service_account = "alertmanager"
      policy          = <<-EOT
        path "kv/data/homelab/alertmanager" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/alertmanager/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-alertmanager/*" {
          capabilities = ["read"]
        }
      EOT
    }

    zot = {
      namespace       = "zot"
      service_account = "zot"
      policy          = <<-EOT
        path "kv/data/homelab/zot" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/zot/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-zot/*" {
          capabilities = ["read"]
        }
      EOT
    }

    argocd-image-updater = {
      namespace       = "argocd"
      service_account = "argocd-image-updater-controller"
      policy          = <<-EOT
        path "kv/data/homelab/argocd-image-updater" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/argocd-image-updater/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-argocd-image-updater/*" {
          capabilities = ["read"]
        }
      EOT
    }

    hdmi-switch = {
      namespace       = "hdmi-switch"
      service_account = "hdmi-switch"
      policy          = <<-EOT
        path "kv/data/homelab/hdmi-switch" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/hdmi-switch/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/k8s-hdmi-switch/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Brand new secret, no legacy path to preserve -- only ever needs the
    # one-key-per-path form.
    github-runner = {
      namespace       = "github-runner"
      service_account = "github-runner"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-github-runner/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Bound to k8s-github-runner's shared CI-job-execution identity (used by
    # both the amd64 and arm64 runner Deployments), not the "github-runner"
    # role above -- that one's for k8s-github-runner's own app credentials
    # (including the GitHub App private key), this is for CI workflows
    # running on the runner to fetch the tofu-state bucket credentials,
    # replacing a static GitHub Actions secret with an in-cluster Vault
    # login. Deliberately a separate, narrower identity from "github-runner"
    # so CI job code never has a path to the App's private key. Only the two
    # tofu-state keys, not all of admin-github/*, to keep this scoped to
    # exactly what CI workflows need.
    github-actions-runner = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/admin-github/tofu-state-access-key-id" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/admin-github/tofu-state-secret-access-key" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/admin-github/github-token" {
          capabilities = ["read"]
        }
      EOT
    }

    # pi-health has no ServiceAccount of its own -- it's a standalone
    # binary on pi1, not a cluster workload -- so this role exists only
    # for CI's apply job (running as github-runner-workload, same shared
    # identity every other CI role uses) to fetch the SSH key it deploys
    # pi-health with.
    pi-health-deploy = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/pi-health/ssh-private-key" {
          capabilities = ["read"]
        }
      EOT
    }

    cert-manager = {
      namespace       = "cert-manager"
      service_account = "homelab-cert-manager"
      policy          = <<-EOT
        path "kv/data/homelab/certmanager" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/certmanager/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-cert-manager-config/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Both notifications and webhook secrets belong to the same repo
    # (homelab-argocd), so the new path is shared even though they're two
    # different roles/ServiceAccounts reading two different old paths.
    argocd-notifications = {
      namespace       = "argocd"
      service_account = "argocd-notifications-controller"
      policy          = <<-EOT
        path "kv/data/homelab/argocd-notifications" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/argocd-notifications/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-argocd/*" {
          capabilities = ["read"]
        }
      EOT
    }

    prometheus = {
      namespace       = "monitoring"
      service_account = "prometheus"
      policy          = <<-EOT
        path "kv/data/homelab/prometheus" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/prometheus/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-prometheus/*" {
          capabilities = ["read"]
        }
      EOT
    }

    argocd-webhook = {
      namespace       = "argocd"
      service_account = "argocd-webhook-secret"
      policy          = <<-EOT
        path "kv/data/homelab/argocd" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/argocd/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-argocd/*" {
          capabilities = ["read"]
        }
      EOT
    }

    graphql-router = {
      namespace       = "graphql-router"
      service_account = "graphql-router"
      policy          = <<-EOT
        path "kv/data/homelab/graphql-router" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/graphql-router/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/k8s-graphql-router/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Reads its own path plus admin-github's -- both old and new forms of
    # each, since neither has migrated yet.
    woodpecker = {
      namespace       = "woodpecker"
      service_account = "woodpecker-server"
      policy          = <<-EOT
        path "kv/data/homelab/woodpecker" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/woodpecker/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-woodpecker/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/gh-org" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/gh-org/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/admin-github/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Separate identity from woodpecker's own role because it needs write
    # access to mint VAULT_TOKEN, not just read -- same path either way.
    woodpecker-bootstrap = {
      namespace       = "woodpecker"
      service_account = "woodpecker-bootstrap"
      policy          = <<-EOT
        path "kv/data/homelab/woodpecker" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/woodpecker/*" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/homelab-woodpecker/*" {
          capabilities = ["read", "create", "update"]
        }
      EOT
    }

    # Old state spans two separate paths (cloudflare, tunnel) that the new
    # scheme consolidates into one -- this role only ever read the
    # `cloudflare` one, so only that old path is granted here.
    cloudflare = {
      namespace       = "cloudflare"
      service_account = "cloudflare"
      policy          = <<-EOT
        path "kv/data/homelab/cloudflare" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/cloudflare/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/homelab-cloudflare/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Reads its own old path (tunnel) and writes the other old path
    # (cloudflare) to mint credentials -- both consolidate into the same
    # new homelab-cloudflare path.
    cloudflare-bootstrap = {
      namespace       = "cloudflare"
      service_account = "cloudflare-bootstrap"
      policy          = <<-EOT
        path "kv/data/homelab/tunnel" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/tunnel/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/cloudflare" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/cloudflare/*" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/homelab-cloudflare/*" {
          capabilities = ["read", "create", "update"]
        }
      EOT
    }

    # Mints its own rpc/admin/metrics secrets, and separately writes the
    # tofu-state bucket's access key into admin-github's path -- a real
    # cross-repo grant, not a mistake. Both old and new forms of each.
    garage = {
      namespace       = "garage"
      service_account = "garage"
      policy          = <<-EOT
        path "kv/data/homelab/garage" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/garage/*" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/k8s-garage/*" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/gh-org" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/gh-org/*" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/admin-github/*" {
          capabilities = ["read", "create", "update"]
        }
      EOT
    }
  }

  # Every individual secret key that should exist as its own KV path,
  # scaffolded blank on first apply and never touched again afterward (see
  # secrets.tf). App prefixes are exact current repo names -- this list is
  # the actual "what secrets exist" answer, keep it in sync as new keys
  # get added anywhere in the homelab.
  #
  # Keys are all lower-case-with-hyphens -- the full KV path
  # (kv/homelab/<app>/<key>) is one continuous path, not an env var, so it
  # stays one consistent style end to end rather than mixing the app
  # segment's hyphens with underscored or SCREAMING_CASE key segments.
  # Whatever casing a consuming app or tool actually requires (an
  # UPPER_SNAKE env var, ARC's literal `github_app_id` field name, etc.)
  # is applied at that app's ExternalSecret via `secretKey`, which maps
  # independently of the Vault path.
  secrets = flatten([
    for app, keys in {
      homelab-alertmanager         = ["discord-webhook-url"]
      homelab-zot                  = ["htpasswd"]
      homelab-argocd-image-updater = ["zot-ci-password"]
      k8s-hdmi-switch              = ["zot-ci-password"]
      homelab-cert-manager-config  = ["cloudflare-api-token"]
      homelab-argocd               = ["discord-webhook-url", "github-webhook-secret"]
      homelab-prometheus           = ["woodpecker-prometheus-auth-token"]
      k8s-graphql-router           = ["zot-ci-password"]
      homelab-woodpecker           = ["github-client", "github-secret", "agent-secret", "vault-token", "prometheus-auth-token", "zot-ci-password"]
      homelab-cloudflare           = ["account-tag", "tunnel-id", "tunnel-secret", "cloudflare-api-token", "cf-account-id"]
      k8s-garage                   = ["rpc-secret", "admin-token", "metrics-token"]
      admin-github                 = ["github-token", "tofu-state-access-key-id", "tofu-state-secret-access-key"]
      k8s-github-runner            = ["github-app-id", "github-app-installation-id", "github-app-private-key"]
      pi-health                    = ["ssh-private-key"]
      } : [
      for key in keys : {
        app = app
        key = key
      }
    ]
  ])
}
