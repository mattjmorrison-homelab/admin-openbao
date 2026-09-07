# Secret migration map

Ground truth for the old-combined-document → new-one-path-per-key
migration described in the README's "Current state vs. this repo's
paths" section. Built by grepping every consuming repo's actual
`ExternalSecret`/CI `kv-path` references directly (2026-09-07) rather
than trusting `locals.tf`'s comments, which had drifted — several
entries there still use a stale `homelab-*` app prefix even though the
owning repo itself was already renamed to `k8s-*` on GitHub.

Every "new path" below is `kv/homelab/<app>/<key>`, property always
`value` (the write-only scaffold in `secrets.tf` always writes
`{value: ""}`). "Scaffolded?" means the destination already exists as a
blank `vault_kv_secret_v2` because `locals.secrets` already has that
exact `{app, key}` pair — if not, it needs adding before anything can
be migrated to it.

## Already on the new path — nothing to do

| App | Path(s) |
| --- | --- |
| `k8s-github-runner` | `github-app-id`, `github-app-installation-id`, `github-app-private-key`, `zot-ci-password` |
| `ui-hdmi-switch` | `discord-webhook-url` |
| `graph-hdmi-switch` | `discord-webhook-url` |
| `admin-discord` | `discord-bot-token` |
| `pi-health` | `ssh-private-key` |
| `k8s-zot` | per-consumer service creds (`service/k8s-zot/<consumer>/<cred>`) |
| `homelab` (nix-control-plane host) | `zot-readonly-password` — never had an old path, born new |
| `pi` | `pi1/private-key`, `pizero/private-key`, `pi5-8/private-key`, `pi5-16/private-key`, `k3s-join-token` — same, born new |

## Ready to migrate now — old path, correctly-named new path, scaffolded, role grants both

| App | Old path | Old property | New path | New property |
| --- | --- | --- | --- | --- |
| `k8s-garage` | `homelab/garage` | `RPC_SECRET` | `homelab/k8s-garage/rpc-secret` | `value` |
| `k8s-garage` | `homelab/garage` | `ADMIN_TOKEN` | `homelab/k8s-garage/admin-token` | `value` |
| `k8s-garage` | `homelab/garage` | `METRICS_TOKEN` | `homelab/k8s-garage/metrics-token` | `value` |
| `k8s-graphql-router` | `homelab/graphql-router` | `ZOT_CI_PASSWORD` | `homelab/k8s-graphql-router/zot-ci-password` | `value` |
| `k8s-hdmi-switch` | `homelab/hdmi-switch` | `ZOT_CI_PASSWORD` | `homelab/k8s-hdmi-switch/zot-ci-password` | `value` |

## Needs a new `locals.secrets` key added first (missing entirely)

| App | Old path | Old property | New path (not yet scaffolded) |
| --- | --- | --- | --- |
| `k8s-argocd` | `homelab/argocd` | `ZOT_CI_PASSWORD` | `homelab/k8s-argocd/zot-ci-password` |
| `k8s-alertmanager` | `homelab/alertmanager` | `DOWNTIME_WEBHOOK_URL` | `homelab/k8s-alertmanager/downtime-webhook-url` |

`k8s-argocd`'s other two keys (`discord-webhook-url`, `github-webhook-secret`)
are already correctly scaffolded under the `k8s-argocd` prefix — only
`zot-ci-password` is missing.

## Needs the `locals.secrets` app prefix renamed first (`homelab-*` → `k8s-*`)

Scaffolded, but under the pre-rename repo name — a `for_each` map key
change on a `prevent_destroy`-guarded resource, so this needs the same
"add new entry, migrate, remove old entry" two-step used for
`homelab-woodpecker`'s archival and the `homelab-zot`/`k8s-zot`
Application rename, not a straight rename in place.

| App | Old path | Old properties | Currently scaffolded as (wrong prefix) | Should be |
| --- | --- | --- | --- | --- |
| `k8s-alertmanager` | `homelab/alertmanager` | `DISCORD_WEBHOOK_URL` | `homelab-alertmanager/discord-webhook-url` | `k8s-alertmanager/discord-webhook-url` |
| `k8s-zot` | `homelab/zot` | `HTPASSWD` | `homelab-zot/htpasswd` | `k8s-zot/htpasswd` |
| `k8s-argocd-image-updater` | `homelab/argocd-image-updater` | `ZOT_CI_PASSWORD` | `homelab-argocd-image-updater/zot-ci-password` | `k8s-argocd-image-updater/zot-ci-password` |
| `k8s-cert-manager-config` | `homelab/certmanager` | `CLOUDFLARE_API_TOKEN` | `homelab-cert-manager-config/cloudflare-api-token` | `k8s-cert-manager-config/cloudflare-api-token` |
| `k8s-cloudflare` | `homelab/cloudflare` | `ACCOUNT_TAG`, `TUNNEL_ID`, `TUNNEL_SECRET` | `homelab-cloudflare/{account-tag,tunnel-id,tunnel-secret}` | `k8s-cloudflare/{...}` |
| `k8s-cloudflare` | `homelab/tunnel` | `CLOUDFLARE_API_TOKEN`, `CF_ACCOUNT_ID` | `homelab-cloudflare/{cloudflare-api-token,cf-account-id}` | `k8s-cloudflare/{...}` |

`k8s-cloudflare` also consolidates two old paths (`homelab/cloudflare` +
`homelab/tunnel`) into one new prefix, on top of the rename.

## Needs investigation before touching — possible value drift

| App | Old path | New path (already live) | Issue |
| --- | --- | --- | --- |
| `admin-github` | `homelab/gh-org` | `homelab/admin-github/{tofu-state-access-key-id,tofu-state-secret-access-key,github-token}` | CI (`actions-tofu/fetch-credentials.sh`) already reads the *new* path directly — but `k8s-garage`'s bootstrap Job still writes fresh tofu-state keys to the *old* `homelab/gh-org` path only, and only if that path doesn't already have a key. No way to tell from code whether old and new currently agree; a blind copy could silently overwrite a working credential with a stale one. Compare the actual values before doing anything here, and repoint `k8s-garage`'s bootstrap script at the new path regardless of what that comparison finds. |

## Being deleted, not migrated

`homelab-woodpecker` and the `woodpecker-prometheus-auth-token` entry
under `homelab-prometheus` — Woodpecker is fully decommissioned, not
renamed. See `.github`'s `docs/migration-checklist.md` entry #2 for
that cleanup's status; the only remaining step there is deleting the
real values in OpenBao so `prevent_destroy` stops blocking their
removal from `locals.secrets`.
