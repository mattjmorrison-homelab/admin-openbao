#!/bin/bash
set -euo pipefail

# One-time diagnostic: count how many "gh-org-tofu-state"-named Garage
# access keys exist. k8s-garage's bootstrap-tofu-state-script-configmap.yaml
# has a bug -- its idempotency check reads the wrong OpenBao path, so it
# never short-circuits and mints a fresh Garage key on every hook run,
# leaking one every time. This script only counts/lists keys, it never
# creates, deletes, or modifies anything.
#
# Requires VAULT_ADDR in the environment. Logs into OpenBao via this
# pod's own Kubernetes ServiceAccount (role: garage-key-audit) to fetch
# Garage's admin token, then queries Garage's admin API directly.

GARAGE_ADMIN_ADDR="${GARAGE_ADMIN_ADDR:-http://garage.garage.svc.cluster.local:3903}"

SA_JWT=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CLIENT_TOKEN=$(curl -sf -X POST "$VAULT_ADDR/v1/auth/kubernetes/login" \
  -d "{\"jwt\": \"$SA_JWT\", \"role\": \"garage-key-audit\"}" | jq -r '.auth.client_token')

GARAGE_ADMIN_TOKEN=$(curl -sf -H "X-Vault-Token: $CLIENT_TOKEN" \
  "$VAULT_ADDR/v1/kv/data/homelab/k8s-garage/admin-token" | jq -r '.data.data.value')
echo "::add-mask::$GARAGE_ADMIN_TOKEN"

KEYS=$(curl -sf -H "Authorization: Bearer $GARAGE_ADMIN_TOKEN" "$GARAGE_ADMIN_ADDR/v2/ListKeys")

echo "## All Garage access keys"
echo "$KEYS" | jq -r '.[] | "\(.id)  \(.name)  created=\(.created)"'
echo
MATCHING=$(echo "$KEYS" | jq -r '[.[] | select(.name == "gh-org-tofu-state")] | length')
echo "## gh-org-tofu-state-named keys: $MATCHING"
if [ "$MATCHING" -gt 1 ]; then
  echo "More than one -- confirms active leakage from the bootstrap script's idempotency bug."
elif [ "$MATCHING" = "1" ]; then
  echo "Exactly one -- no leakage observed yet, but the bug is still present and will start leaking on the next hook run."
else
  echo "None found -- the hook may not have run yet, or uses a different key name than expected."
fi
