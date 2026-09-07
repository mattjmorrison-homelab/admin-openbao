#!/bin/bash
set -euo pipefail

# Read-only inventory of everything currently live in OpenBao: every KV v2
# secret PATH under kv/homelab (never a value -- only LIST on
# kv/metadata/*, never GET on kv/data/*), every Kubernetes auth role's
# config, and every ACL policy's rules. Used to cross-check the live
# state against locals.tf's documented standard (one secret per
# kv/homelab/<app>/<key> path, single "value" property) and to find real
# usage across the org that doesn't match it.
#
# Requires VAULT_ADDR and VAULT_TOKEN in the environment.

list() {
  curl -sf -H "X-Vault-Token: $VAULT_TOKEN" -X LIST "$VAULT_ADDR/v1/$1" 2>/dev/null \
    | jq -r '.data.keys[]? // empty'
}

read_json() {
  curl -sf -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/$1" 2>/dev/null
}

walk_kv_keys() {
  local prefix="$1"
  local entry
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if [[ "$entry" == */ ]]; then
      walk_kv_keys "${prefix}${entry}"
    else
      echo "kv/homelab/${prefix}${entry}"
    fi
  done < <(list "kv/metadata/homelab/${prefix}")
}

echo "## Secret paths (kv/homelab/*)"
echo
walk_kv_keys ""
echo

echo "## Kubernetes auth roles"
echo
while IFS= read -r role; do
  [ -z "$role" ] && continue
  echo "### $role"
  read_json "auth/kubernetes/role/$role" \
    | jq '{bound_service_account_names, bound_service_account_namespaces, token_policies}'
  echo
done < <(list "auth/kubernetes/role")

echo "## ACL policies"
echo
while IFS= read -r policy; do
  [ -z "$policy" ] && continue
  case "$policy" in
    default | root) continue ;;
  esac
  echo "### $policy"
  read_json "sys/policies/acl/$policy" | jq -r '.data.policy'
  echo
done < <(list "sys/policies/acl")
