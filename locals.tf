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

    # Narrowed for real, 2026-09-24: the first attempt at this (#40)
    # broke live service because k8s-zot's 9 per-consumer
    # zot-service-cred-<name> ExternalSecrets (external-secret-service-
    # consumers.yaml) also authenticated via this same role/SecretStore
    # to read service/k8s-zot/<name>/<cred>, reverted in #43. Since then,
    # every real consumer migrated onto its own dedicated OpenBao role
    # reading its own path directly (Phase 2, #47-#53), and k8s-zot#14
    # removed that now-fully-unused delivery mechanism entirely --
    # confirmed live, zero zot-service-cred-* Secrets remain, Application
    # Healthy. Nothing left reads service/k8s-zot/* via this role.
    zot = {
      namespace       = "zot"
      service_account = "zot"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-zot/htpasswd" {
          capabilities = ["read"]
        }
      EOT
    }

    # Narrowed 2026-09-24: k8s-argocd-image-updater's ExternalSecret is
    # confirmed repointed and live (k8s-argocd-image-updater#3) -- old
    # bare/k8s-argocd-image-updater/* grant dropped, confirmed nothing
    # else in the org references the old path anymore.
    argocd-image-updater = {
      namespace       = "argocd"
      service_account = "argocd-image-updater-controller"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/k8s-argocd-image-updater/zot-pull" {
          capabilities = ["read"]
        }
      EOT
    }

    # Narrowed 2026-09-24: k8s-hdmi-switch's ExternalSecret is confirmed
    # repointed and live (k8s-hdmi-switch#3) -- old bare/k8s-hdmi-switch/*
    # grants dropped, confirmed nothing else in the org references
    # either old path anymore.
    hdmi-switch = {
      namespace       = "hdmi-switch"
      service_account = "hdmi-switch"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/k8s-hdmi-switch/zot-pull" {
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

    # Same per-purpose-role convention as ui-hdmi-switch-discord/
    # graph-hdmi-switch-discord -- shared github-runner-workload
    # identity, but its own dedicated role/policy, scoped to only
    # admin-discord's own tofu-state credential. Phase 1b (#39):
    # replaces admin-discord's use of the shared github-actions-runner
    # role/bucket above, once its state migration is confirmed live.
    admin-discord-tofu-state = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-garage/admin-discord/tofu-state-access-key-id" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/k8s-garage/admin-discord/tofu-state-secret-access-key" {
          capabilities = ["read"]
        }
      EOT
    }

    # Same per-purpose-role convention as admin-discord-tofu-state above,
    # plus admin-github's own github-token -- unlike every other
    # migrating repo, admin-github's own Terraform provider needs a
    # GITHUB_TOKEN too (fetch-credentials' needs-github-token: true),
    # which the old shared github-actions-runner role used to also
    # grant. Confirmed the hard way: the first version of this role
    # only had the two tofu-state keys, and admin-github's migration
    # workflow failed fetching github-token with that grant missing.
    admin-github-tofu-state = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-garage/admin-github/tofu-state-access-key-id" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/k8s-garage/admin-github/tofu-state-secret-access-key" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/admin-github/github-token" {
          capabilities = ["read"]
        }
      EOT
    }

    # Same per-purpose-role convention as admin-discord-tofu-state/
    # admin-github-tofu-state above. Self-referential (this repo defines
    # its own migration credential), but no different in kind -- this
    # role governs admin-openbao's CI identity, not admin-openbao's own
    # OpenBao management capabilities.
    admin-openbao-tofu-state = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-garage/admin-openbao/tofu-state-access-key-id" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/k8s-garage/admin-openbao/tofu-state-secret-access-key" {
          capabilities = ["read"]
        }
      EOT
    }

    # Same per-purpose-role convention as admin-discord-tofu-state/
    # admin-github-tofu-state/admin-openbao-tofu-state above. Separate
    # from the existing "admin-cloudflare" role (which grants
    # cloudflare-api-token/cf-account-id) -- this one is purely for the
    # tofu-state credential, matching every other migrated repo.
    admin-cloudflare-tofu-state = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-garage/admin-cloudflare/tofu-state-access-key-id" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/k8s-garage/admin-cloudflare/tofu-state-secret-access-key" {
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
    # Grants both the old client-only-named path (still read/written by
    # Narrowed 2026-09-26: ui-hdmi-switch#7 confirmed merged --
    # admin-discord now owns creating and writing this value itself
    # (its own dedicated webhook object + admin-discord-webhooks role),
    # and publish.yml no longer writes here at all. Old
    # github-actions/ui-hdmi-switch/webhook-url grant dropped; this role
    # only needs READ on the new admin-discord-owned path.
    ui-hdmi-switch-discord = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/ui-hdmi-switch/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/admin-discord/ui-hdmi-switch/webhook-url" {
          capabilities = ["read"]
        }
      EOT
    }

    # Narrowed 2026-09-26: graph-hdmi-switch#5 confirmed merged --
    # same cutover as ui-hdmi-switch-discord above.
    graph-hdmi-switch-discord = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/graph-hdmi-switch/*" {
          capabilities = ["read"]
        }
        path "kv/data/homelab/service/admin-discord/graph-hdmi-switch/webhook-url" {
          capabilities = ["read"]
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

    # Separate role from "admin-discord" above (different purpose,
    # same shared github-runner-workload identity, per this repo's
    # per-purpose-role convention) -- write-only, scoped to exactly
    # the consumer paths admin-discord's own apply job pushes each
    # dedicated webhook's real URL into, right after creating it. No
    # broader grant: admin-discord's CI has no business reading these
    # paths back, only writing them.
    admin-discord-webhooks = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/admin-discord/ui-hdmi-switch/webhook-url" {
          capabilities = ["create", "update"]
        }
        path "kv/data/homelab/service/admin-discord/graph-hdmi-switch/webhook-url" {
          capabilities = ["create", "update"]
        }
      EOT
    }

    # admin-cloudflare's CI (check/apply) reads its own dedicated
    # credentials -- a separate, narrower-scoped Cloudflare API token
    # (Zone:Read, DNS:Edit, Account:Cloudflare Tunnel:Read, restricted to
    # morrisons.site) from the one k8s-cloudflare's in-cluster
    # cloudflare-bootstrap role uses (which also needs Tunnel:Edit to
    # create the tunnel itself). Two different consumers must never read
    # the same credential, even when the values happen to be readable by
    # the same Cloudflare account -- that's exactly the sharing this
    # homelab's secrets standard exists to prevent.
    admin-cloudflare = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/admin-cloudflare/*" {
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
    #
    # Migrated (2026-09-24) from kv/data/homelab/k8s-lib-ci-rbac/* (a path
    # that was never actually populated -- this workflow never successfully
    # published against a live registry) to its real, already-provisioned
    # per-consumer Zot credential -- Phase 2 of the secrets-standard-
    # compliance work, off the shared ci admin user.
    k8s-lib-ci-rbac-publish = {
      namespace       = "github-runner"
      service_account = "github-runner-workload"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/k8s-lib-ci-rbac/zot-publish" {
          capabilities = ["read"]
        }
      EOT
    }

    # Bound to each Kaniko job's own dedicated ServiceAccount
    # (k8s-ci-rbac's jobServiceAccounts), not the shared
    # github-runner-workload identity above -- unlike k8s-lib-ci-rbac-
    # publish (which fetches from a GitHub Actions workflow step), these
    # 3 credentials are delivered in-cluster via each job's own
    # SecretStore/ExternalSecret (k8s-ci-rbac's job-zot-pull-secret.yaml),
    # so the auth identity is the job's own ServiceAccount. Replaces the
    # old shared zot-pull-secret/ci admin user these Kaniko jobs used to
    # pull from -- part of Phase 2 of the secrets-standard-compliance work.
    graph-router = {
      namespace       = "github-runner"
      service_account = "graph-router-job"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/graph-router/zot-publish" {
          capabilities = ["read"]
        }
      EOT
    }

    graph-hdmi-switch = {
      namespace       = "github-runner"
      service_account = "graph-hdmi-switch-job"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/graph-hdmi-switch/zot-publish" {
          capabilities = ["read"]
        }
      EOT
    }

    ui-hdmi-switch = {
      namespace       = "github-runner"
      service_account = "ui-hdmi-switch-job"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/ui-hdmi-switch/zot-publish" {
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
        path "kv/data/homelab/k8s-argocd/discord-webhook-url" {
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
        path "kv/data/homelab/k8s-argocd/github-webhook-secret" {
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
    # Narrowed 2026-09-24: repo-creds-oci-external-secret.yaml is confirmed
    # repointed and live (k8s-argocd#5) -- old exact-key grant dropped,
    # confirmed nothing else in the org references the old path anymore.
    argocd-repo-creds-oci = {
      namespace       = "argocd"
      service_account = "argocd-repo-creds-oci-secret"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/k8s-argocd/zot-pull" {
          capabilities = ["read"]
        }
      EOT
    }

    # Narrowed 2026-09-24: k8s-graphql-router's ExternalSecret is
    # confirmed repointed and live (k8s-graphql-router#3) -- old bare/
    # k8s-graphql-router/* grants dropped, confirmed nothing else in
    # the org references either old path anymore.
    graphql-router = {
      namespace       = "graphql-router"
      service_account = "graphql-router"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/k8s-graphql-router/zot-pull" {
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
        path "kv/data/homelab/k8s-zot/htpasswd" {
          capabilities = ["read", "create", "update"]
        }
      EOT
    }

    # PostSync verify Job's identity -- read-only on its own dedicated
    # Zot service-credential (a normal serviceConsumers entry, same
    # mechanism as every other real consumer, not a shared account like
    # ci-readonly). Catches a broken htpasswd merge (empty or missing
    # entry) immediately via a real authenticated request, instead of
    # silently.
    zot-verify = {
      namespace       = "zot"
      service_account = "zot-verify"
      policy          = <<-EOT
        path "kv/data/homelab/service/k8s-zot/zot-verify/verify-password" {
          capabilities = ["read"]
        }
      EOT
    }

    # Mints its own rpc/admin/metrics secrets, and separately writes the
    # tofu-state bucket's access key into admin-github's path -- a real
    # cross-repo grant, not a mistake. Scoped to the 2 exact keys its own
    # bootstrap script touches (not a wildcard) -- read is needed because
    # the script's idempotency check reads before writing.
    # The admin-github/tofu-state-* grant is the old shared bucket/key
    # this bootstrap job used to mint once for every repo -- kept until
    # every repo has migrated off it (Phase 1b decommissioning), even
    # though the new mechanism below writes real per-repo credentials
    # instead. service/k8s-garage/* is this job's own provider prefix,
    # same pattern as zot-bootstrap's service/k8s-zot/* grant.
    garage = {
      namespace       = "garage"
      service_account = "garage"
      policy          = <<-EOT
        path "kv/data/homelab/k8s-garage/*" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/admin-github/tofu-state-access-key-id" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/admin-github/tofu-state-secret-access-key" {
          capabilities = ["read", "create", "update"]
        }
        path "kv/data/homelab/service/k8s-garage/*" {
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
  #
  # Scaffolded here (blank) BEFORE k8s-zot's own values.yaml registers
  # these as serviceConsumers -- deliberately, so Terraform's one-time
  # blank write happens first. If k8s-zot's bootstrap script wrote a
  # real password before this ever applied, this resource's first-ever
  # write (which only ever happens once, ever) would create a new blank
  # version on top of it, silently superseding the real one.
  service_credentials = [
    { provider = "k8s-zot", consumer = "k8s-graphql-router", cred = "zot-pull" },
    { provider = "k8s-zot", consumer = "k8s-hdmi-switch", cred = "zot-pull" },
    { provider = "k8s-zot", consumer = "k8s-argocd", cred = "zot-pull" },
    { provider = "k8s-zot", consumer = "k8s-argocd-image-updater", cred = "zot-pull" },
    { provider = "k8s-zot", consumer = "k8s-lib-ci-rbac", cred = "zot-publish" },
    { provider = "k8s-zot", consumer = "graph-router", cred = "zot-publish" },
    { provider = "k8s-zot", consumer = "graph-hdmi-switch", cred = "zot-publish" },
    { provider = "k8s-zot", consumer = "ui-hdmi-switch", cred = "zot-publish" },
    { provider = "k8s-zot", consumer = "zot-verify", cred = "verify-password" },

    # Per-repo Garage tofu-state bucket credentials -- replaces the old
    # single shared bucket/key every Terraform repo used to read from
    # admin-github's own path. k8s-garage's bootstrap job mints one
    # bucket + one key per repo and writes both here, same provider/
    # consumer pattern as k8s-zot's credentials above.
    { provider = "k8s-garage", consumer = "admin-discord", cred = "tofu-state-access-key-id" },
    { provider = "k8s-garage", consumer = "admin-discord", cred = "tofu-state-secret-access-key" },
    { provider = "k8s-garage", consumer = "admin-github", cred = "tofu-state-access-key-id" },
    { provider = "k8s-garage", consumer = "admin-github", cred = "tofu-state-secret-access-key" },
    { provider = "k8s-garage", consumer = "admin-openbao", cred = "tofu-state-access-key-id" },
    { provider = "k8s-garage", consumer = "admin-openbao", cred = "tofu-state-secret-access-key" },
    # admin-cloudflare didn't exist when the original 3-repo list was
    # written -- confirmed via grepping every repo's provider.tf for
    # `backend "s3"` that it's on the same shared bucket too.
    { provider = "k8s-garage", consumer = "admin-cloudflare", cred = "tofu-state-access-key-id" },
    { provider = "k8s-garage", consumer = "admin-cloudflare", cred = "tofu-state-secret-access-key" },

    # admin-discord owns creating each consumer's own dedicated Discord
    # webhook (no longer one shared webhook -- see admin-discord's own
    # locals.tf) and pushes the real URL here itself, right after
    # creating it, via the admin-discord-webhooks role below. Consumers
    # only ever read their own path -- no more reaching into
    # admin-discord's raw Terraform state (the old read-output
    # mechanism this replaces).
    { provider = "admin-discord", consumer = "ui-hdmi-switch", cred = "webhook-url" },
    { provider = "admin-discord", consumer = "graph-hdmi-switch", cred = "webhook-url" },
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
      k8s-argocd = ["discord-webhook-url", "github-webhook-secret"]
      k8s-garage = ["rpc-secret", "admin-token", "metrics-token"]

      k8s-alertmanager        = ["discord-webhook-url", "downtime-webhook-url"]
      k8s-zot                 = ["htpasswd"]
      k8s-cert-manager-config = ["cloudflare-api-token"]
      k8s-cloudflare          = ["account-tag", "tunnel-id", "tunnel-secret", "cloudflare-api-token", "cf-account-id"]
      admin-github            = ["github-token", "tofu-state-access-key-id", "tofu-state-secret-access-key"]
      k8s-github-runner       = ["github-app-id", "github-app-installation-id", "github-app-private-key"]
      admin-discord           = ["discord-bot-token"]
      admin-cloudflare        = ["cloudflare-api-token", "cf-account-id"]
      pi-health               = ["ssh-private-key"]
      pi                      = ["pi1/private-key", "pizero/private-key", "pi5-8/private-key", "pi5-16/private-key", "k3s-join-token"]
      homelab                 = ["zot-readonly-password"]
      } : [
      for key in keys : {
        app = app
        key = key
      }
    ]
  ]))

}
