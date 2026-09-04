# admin-openbao

OpenTofu config managing OpenBao's own policies, Kubernetes auth roles, and
KV secret paths, using the [`hashicorp/vault`](https://registry.terraform.io/providers/hashicorp/vault/latest)
provider (Vault-API-compatible, works against OpenBao unchanged). See
`naming.md`'s `admin-` prefix — same category as `admin-github`,
administering another system's own policy/access-control layer rather than
deploying a workload.

## Why

Disaster recovery. Before this repo, every app's OpenBao role and policy
was created by hand via OpenBao's own UI, and the only way to know what
secrets exist at all was reading through application code and manifests
across every repo. If OpenBao's data were lost, rebuilding it correctly
meant reverse-engineering that from scratch. Now: `tofu apply` recreates
every policy, role, and secret path exactly, and `locals.tf` is the single
place that answers "what secrets exist and who can read them."

## What this manages, and what it deliberately doesn't

- `auth.tf` — a `vault_policy` and `vault_kubernetes_auth_backend_role`
  per entry in `locals.roles`, matching every SecretStore and bootstrap
  script's Kubernetes-auth role across the whole homelab exactly as
  captured on 2026-08-21.
- `approle.tf` — AppRole auth backend for nix-control-plane (the homelab's
  only non-pod identity), scoped to exactly one KV path
  (`kv/homelab/homelab/zot-readonly-password`), narrower than Kubernetes
  roles (which grant `path` + `path/*`). Secret_id is issued out-of-band,
  not a Terraform resource, to avoid storing it in state.
- `secrets.tf` — a `vault_kv_secret_v2` per entry in `locals.secrets`,
  one KV path per individual secret (`kv/homelab/<app>/<key>`), written
  via `data_json_wo` (Terraform's write-only argument) so the value is
  never stored in state and never re-applied after the first `tofu apply`
  — a value typed into the path afterward, in OpenBao directly, is
  permanently safe. Every segment of the path, including `<key>`, is
  lower-case-with-hyphens — one consistent style for the whole path
  rather than mixing in whatever casing a consuming app happens to want
  (an UPPER_SNAKE env var, ARC's literal `github_app_id` field name,
  etc.); that translation happens at each app's `ExternalSecret` via
  `secretKey`, independently of the Vault path.

**Does not manage secret values.** Every path gets created blank; typing
in the real value is a manual, one-time step per secret, same as it's
always been — this repo's job stops at making sure the path, and the role
that can read it, already exist correctly.

**Every policy grants both the old and new path, on purpose, until an app
actually migrates.** Vault policy writes fully replace the previous
document — applying a policy that only covers the new (target) path would
immediately break secret refresh for every app still reading the old one,
which today is all of them. Each role's `policy` in `locals.tf` grants
both forms; drop the old-path block for a given app only once its
`ExternalSecret`s have actually been repointed and verified against the
new path.

## Current state vs. this repo's paths

This repo declares the **target** KV layout (one path per secret, app
prefix matching each secret's owning repo's exact current name — e.g.
`kv/homelab/homelab-woodpecker/*`, `kv/homelab/k8s-garage/*`,
`kv/homelab/admin-github/*`). The apps consuming these secrets mostly
still read from the **old** combined per-app paths (short informal names
like `kv/homelab/woodpecker`, `kv/homelab/garage`, `kv/homelab/gh-org`,
holding several keys as one JSON document) — migration is incremental,
one app at a time: copy the real value from the old path into the new
one, repoint that app's `ExternalSecret`s, deploy, verify, move to the
next app. Old paths and their policies stay until every consumer relying
on them has moved. Two consolidations already differ from today's live
paths, both deliberate — same repo, one app prefix, even where multiple
roles or legacy paths existed separately before:

- `homelab-cloudflare`'s keys consolidate what are currently **two**
  separate paths (`kv/homelab/cloudflare` and `kv/homelab/tunnel`).
- `k8s-argocd`'s keys (renamed from `homelab-argocd`) consolidate the
  notifications and webhook secrets (`kv/homelab/argocd-notifications`
  and `kv/homelab/argocd`), which both belong to the same repo despite
  being read by two different roles. That rename is itself mid-migration:
  both the old `homelab-argocd` and new `k8s-argocd` entries exist in
  `locals.secrets`, and only the `argocd-notifications` role's policy
  grants the new `kv/homelab/k8s-argocd/*` path so far, alongside the
  `kv/homelab/homelab-argocd/*` grant both roles already had;
  `argocd-webhook`'s policy hasn't picked up the new path yet.

## Local usage

```sh
export VAULT_ADDR=https://openbao.morrisons.site
export VAULT_TOKEN=<the OpenBao root token, from your password manager>
export AWS_ACCESS_KEY_ID=<TOFU_STATE_ACCESS_KEY_ID from kv/homelab/gh-org>
export AWS_SECRET_ACCESS_KEY=<TOFU_STATE_SECRET_ACCESS_KEY from kv/homelab/gh-org>
tofu init
tofu plan
tofu apply
```

`VAULT_ADDR` is the external URL when running locally; CI uses the
in-cluster address instead (`.woodpecker.yml`). Same S3-endpoint caveat as
`admin-github` applies for the state backend when running outside the
cluster — see that repo's README for the port-forward workaround.

## Adding a new secret or role

Add it to `locals.roles` and/or `locals.secrets`, then `tofu apply`. If the identity isn't a Kubernetes pod/ServiceAccount (e.g., a host or external system), don't use `locals.roles` — instead follow the pattern in `approle.tf`: create a `vault_auth_backend`, `vault_policy`, and auth-backend-specific role resource.

## CI

`.woodpecker.yml` runs `tofu plan` on every push/PR, `tofu apply` on push
to `main`. `VAULT_TOKEN` comes from Woodpecker's own native secret store
(`vault_root_token` — Settings → Secrets in Woodpecker's UI, **not**
OpenBao), the same reason `admin-github`'s GitHub token bootstrap
credential can't come from OpenBao either: it's the credential that
unlocks the thing being managed, so it can't be sourced from that thing.
State-bucket credentials reuse the same native Kubernetes secret
(`gh-org-github-token`) `admin-github` already uses.

**Manual step needed, can't be done from here:** create the
`vault_root_token` secret in Woodpecker's Settings → Secrets, value = the
OpenBao root token.
