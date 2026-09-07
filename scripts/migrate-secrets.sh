#!/bin/bash
set -euo pipefail

# One-time migration: copies each real secret value from its old
# combined-document path to its new one-path-per-key location. Deleted
# after use -- see docs/secret-migration-map.md for the full picture and
# .github/workflows/migrate-secrets.yml for how this gets run.
#
# Deliberately excludes admin-github (old/new path value-drift needs a
# manual comparison first, see the migration map) and homelab-woodpecker
# (being deleted, not migrated).

DRY_RUN="${DRY_RUN:-true}"

# old_path old_property new_path
MIGRATIONS='
homelab/garage RPC_SECRET homelab/k8s-garage/rpc-secret
homelab/garage ADMIN_TOKEN homelab/k8s-garage/admin-token
homelab/garage METRICS_TOKEN homelab/k8s-garage/metrics-token
homelab/graphql-router ZOT_CI_PASSWORD homelab/k8s-graphql-router/zot-ci-password
homelab/hdmi-switch ZOT_CI_PASSWORD homelab/k8s-hdmi-switch/zot-ci-password
homelab/argocd ZOT_CI_PASSWORD homelab/k8s-argocd/zot-ci-password
homelab/argocd-notifications DISCORD_WEBHOOK_URL homelab/k8s-argocd/discord-webhook-url
homelab/argocd GITHUB_WEBHOOK_SECRET homelab/k8s-argocd/github-webhook-secret
homelab/alertmanager DISCORD_WEBHOOK_URL homelab/k8s-alertmanager/discord-webhook-url
homelab/alertmanager DOWNTIME_WEBHOOK_URL homelab/k8s-alertmanager/downtime-webhook-url
homelab/zot HTPASSWD homelab/k8s-zot/htpasswd
homelab/argocd-image-updater ZOT_CI_PASSWORD homelab/k8s-argocd-image-updater/zot-ci-password
homelab/certmanager CLOUDFLARE_API_TOKEN homelab/k8s-cert-manager-config/cloudflare-api-token
homelab/cloudflare ACCOUNT_TAG homelab/k8s-cloudflare/account-tag
homelab/cloudflare TUNNEL_ID homelab/k8s-cloudflare/tunnel-id
homelab/cloudflare TUNNEL_SECRET homelab/k8s-cloudflare/tunnel-secret
homelab/tunnel CLOUDFLARE_API_TOKEN homelab/k8s-cloudflare/cloudflare-api-token
homelab/tunnel CF_ACCOUNT_ID homelab/k8s-cloudflare/cf-account-id
'

failures=0

while read -r old_path old_prop new_path; do
  [ -z "$old_path" ] && continue

  echo "=== $old_path.$old_prop -> $new_path ==="

  VALUE=$(curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/kv/data/$old_path" \
    | jq -r --arg p "$old_prop" '.data.data[$p] // empty')

  if [ -z "$VALUE" ]; then
    echo "  SKIP: $old_path has no $old_prop property" >&2
    failures=$((failures + 1))
    continue
  fi

  echo "::add-mask::$VALUE"

  if [ "$DRY_RUN" = "true" ]; then
    echo "  DRY RUN: fetched OK, would write to $new_path"
    continue
  fi

  curl -sf -H "X-Vault-Token: $VAULT_TOKEN" -X POST "$VAULT_ADDR/v1/kv/data/$new_path" \
    -d "$(jq -n --arg v "$VALUE" '{data: {value: $v}}')" > /dev/null

  echo "  OK: written"
done <<< "$MIGRATIONS"

if [ "$failures" -gt 0 ]; then
  echo "$failures migration(s) failed to fetch a source value -- see SKIP lines above" >&2
  exit 1
fi
