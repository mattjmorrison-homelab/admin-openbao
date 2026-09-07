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
        path "kv/data/homelab/k8s-alertmanager/*" {
          capabilities = ["read"]
        }
      EOT
    }

    zot = {
      namespace       = "zot"
      service_account = "zot"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-zot" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/k8s-zot/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/k8s-zot/*" {
          capabilities = ["read"]
        }
      EOT
    }

    argocd-image-updater = {
      namespace       = "argocd"
      service_account = "argocd-image-updater-controller"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-argocd-image-updater/*" {
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

    # One narrow role per repo needing its own Discord webhook, bound to
    # the same shared github-runner-workload identity as every other CI
    # role -- deliberately not the "github-runner"/"github-actions-runner"
    # roles above, which are scoped to their own separate purposes. Same
    # per-purpose-role convention as pi-health-deploy/k8s-lib-ci-rbac-publish
    # below. Woodpecker's own discord_webhook_url secret for this repo was
    # never in OpenBao -- confirm/create the real value at this path
    # manually before actions-openbao's fetch can work.
    # Also grants create/update (not just read) on discord-webhook-url:
    # this role's own repo writes that one value itself, pulled from
    # admin-discord's Terraform state via actions-tofu/read-output, so
    # admin-discord never needs write access to another repo's secrets.
    ui-hdmi-switch-discord = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/ui-hdmi-switch/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/ui-hdmi-switch/discord-webhook-url" {
          capabilities = ["create", "update"]
        }
      EOT
    }

    # Same per-purpose-role convention as ui-hdmi-switch-discord above,
    # including the same create/update grant on discord-webhook-url.
    graph-hdmi-switch-discord = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/graph-hdmi-switch/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/graph-hdmi-switch/discord-webhook-url" {
          capabilities = ["create", "update"]
        }
      EOT
    }

    # admin-discord's own bot token, fetched by its CI (check/apply) via
    # actions-openbao before running tofu plan/apply -- separate from the
    # shared github-actions-runner role above, which only ever grants the
    # Garage tofu-state credentials every Terraform repo needs, never a
    # repo-specific secret like this one.
    admin-discord = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/admin-discord/*" {
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

    # Bound to its own dedicated ServiceAccount (pi-provision-runner in
    # k8s-github-runner), NOT github-runner-workload -- these keys can join
    # new nodes to the whole cluster (k3s-join-token) or reach any Pi in the
    # fleet, so this role is deliberately isolated: OpenBao's Kubernetes
    # auth only checks which ServiceAccount a login's JWT belongs to, so
    # sharing the everyday CI identity here would mean any repo's workflow
    # could request this role and read these keys too. Path is keyed by
    # device name ("pi/<name>/...") rather than an owning repo, since these
    # keys belong to the physical Pis themselves, not to pi-provision
    # specifically -- pi-health's own separate pi1 key (below) predates
    # this and is intentionally left alone, not migrated in.
    pi-provision-deploy = {
      namespace       = "github-runner"
      service_account = "pi-provision-runner"
      policy          = <<-EOT
        path "kv/data/homelab/pi/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # Narrow, per-purpose CI credential fetch using the shared
    # github-runner-workload identity (same pattern as github-actions-runner/
    # pi-health-deploy/pi-provision-deploy), deliberately not reusing the
    # github-actions-runner role itself since that role's policy is scoped
    # narrower to just tofu-state/github-token.
    k8s-lib-ci-rbac-publish = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-lib-ci-rbac/*" {
          capabilities = ["read"]
        }
      EOT
    }

    cert-manager = {
      namespace       = "cert-manager"
      service_account = "homelab-cert-manager"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-cert-manager-config/*" {
          capabilities = ["read"]
        }
      EOT
    }

    argocd-notifications = {
      namespace       = "argocd"
      service_account = "argocd-notifications-controller"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-argocd/*" {
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
        path "kv/data/homelab/k8s-argocd/*" {
          capabilities = ["read"]
        }
      EOT
    }

    # ArgoCD's repo-server component (resolves Helm OCI chart dependencies at
    # sync time) -- a different ServiceAccount from argocd-webhook/
    # argocd-notifications above, which bind to argocd-webhook-secret/
    # argocd-notifications-controller instead. Authenticates via a dedicated
    # secret-fetcher ServiceAccount (argocd-repo-creds-oci-secret), matching
    # the argocd-webhook/argocd-webhook-secret pattern, not repo-server's own
    # ServiceAccount -- k8s-argocd's SecretStore requests this exact role.
    argocd-repo-creds-oci = {
      namespace       = "argocd"
      service_account = "argocd-repo-creds-oci-secret"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-argocd/*" {
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

    cloudflare = {
      namespace       = "cloudflare"
      service_account = "cloudflare"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-cloudflare/*" {
          capabilities = ["read"]
        }
      EOT
    }

    cloudflare-bootstrap = {
      namespace       = "cloudflare"
      service_account = "cloudflare-bootstrap"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-cloudflare/*" {
          capabilities = ["read", "create", "update"]
        }
      EOT
    }

    # Provider side of the service-credentials pattern (see
    # `service_credentials` below): a dedicated bootstrap identity, not
    # the `zot` role above (that one's read-only, for Zot's own pod to
    # read its own htpasswd secret) -- same split as
    # cloudflare/cloudflare-bootstrap and woodpecker/woodpecker-bootstrap.
    # One wildcard write grant covers every consumer's leaf under this
    # provider, so adding a new consumer never needs a policy change here.
    zot-bootstrap = {
      namespace       = "zot"
      service_account = "zot-bootstrap"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/*" {
          capabilities = ["read", "create", "update"]
        }
      EOT
    }

    # Consumer side: k8s-garage's CI (github-runner-workload, same shared
    # identity as k8s-lib-ci-rbac-publish/pi-health-deploy) reads exactly
    # its one credential to log into the registry before `helm dependency
    # build`. Scoped to this one cred, not all of
    # service/k8s-zot/k8s-garage/*, since that's all this role needs.
    k8s-garage-pull-helm-libs = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/k8s-garage/pull-helm-libs" {
          capabilities = ["read"]
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

  # Service-to-service credentials: the provider generates one, the
  # consumer reads it. Path shape is
  # kv/homelab/service/<provider>/<consumer>/<cred> -- one path per
  # secret, folded into `secrets` below via the same {app, key} shape
  # every other entry uses (app = "service/<provider>/<consumer>", key =
  # <cred>), so secrets.tf needs no changes to scaffold these too.
  service_credentials = [
    {
      provider = "k8s-zot"
      consumer = "k8s-garage"
      cred     = "pull-helm-libs"
    },
  ]

  service_secrets = [
    for sc in local.service_credentials : {
      app = "service/${sc.provider}/${sc.consumer}"
      key = sc.cred
    }
  ]

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
  secrets = concat(local.service_secrets, flatten([
    for app, keys in {
      # Stale homelab-* prefix, kept until the secret-migration-map.md
      # "prefix rename" apps actually migrate -- see that doc. The
      # correctly-prefixed k8s-* entries below are the new scaffold for
      # the same secrets, added alongside these, not replacing them yet.
      homelab-alertmanager         = ["discord-webhook-url"]
      homelab-zot                  = ["htpasswd"]
      homelab-argocd-image-updater = ["zot-ci-password"]
      k8s-hdmi-switch              = ["zot-ci-password"]
      homelab-cert-manager-config  = ["cloudflare-api-token"]
      k8s-argocd                   = ["discord-webhook-url", "github-webhook-secret", "zot-ci-password"]
      homelab-argocd               = ["discord-webhook-url", "github-webhook-secret"]
      homelab-prometheus           = ["woodpecker-prometheus-auth-token"]
      k8s-graphql-router           = ["zot-ci-password"]
      k8s-lib-ci-rbac              = ["zot-ci-password"]
      homelab-woodpecker           = ["github-client", "github-secret", "agent-secret", "vault-token", "prometheus-auth-token", "zot-ci-password"]
      homelab-cloudflare           = ["account-tag", "tunnel-id", "tunnel-secret", "cloudflare-api-token", "cf-account-id"]
      k8s-garage                   = ["rpc-secret", "admin-token", "metrics-token"]

      # New, correctly-prefixed scaffolds for apps still on a stale
      # homelab-* entry above -- see secret-migration-map.md.
      k8s-alertmanager         = ["discord-webhook-url", "downtime-webhook-url"]
      k8s-zot                  = ["htpasswd"]
      k8s-argocd-image-updater = ["zot-ci-password"]
      k8s-cert-manager-config  = ["cloudflare-api-token"]
      k8s-cloudflare           = ["account-tag", "tunnel-id", "tunnel-secret", "cloudflare-api-token", "cf-account-id"]
      admin-github             = ["github-token", "tofu-state-access-key-id", "tofu-state-secret-access-key"]
      k8s-github-runner        = ["github-app-id", "github-app-installation-id", "github-app-private-key", "zot-ci-password"]
      ui-hdmi-switch           = ["discord-webhook-url"]
      graph-hdmi-switch        = ["discord-webhook-url"]
      admin-discord            = ["discord-bot-token"]
      pi-health                = ["ssh-private-key"]
      pi                       = ["pi1/private-key", "pizero/private-key", "pi5-8/private-key", "pi5-16/private-key", "k3s-join-token"]
      homelab                  = ["zot-readonly-password"]
      } : [
      for key in keys : {
        app = app
        key = key
      }
    ]
  ]))

  # "<app>/<key>" entries confirmed to have zero real consumers anywhere
  # (checked ExternalSecrets, CI workflows, and bootstrap scripts across
  # every repo, not just Vault policy grants -- some real secrets are
  # read via constructed paths a static grant/reference check alone would
  # miss). Referenced only by secrets.tf's prevent_destroy override below,
  # step 1 of a two-step retirement: this list lifts the destroy guard for
  # exactly these keys (no resource diff yet), then a follow-up PR removes
  # them from `secrets` above once the real OpenBao values are deleted
  # manually. Once that follow-up PR merges, this list (and the
  # prevent_destroy override referencing it) should be deleted too --
  # don't leave it behind as permanent scaffolding.
  retiring_secrets = [
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
  ]
}
