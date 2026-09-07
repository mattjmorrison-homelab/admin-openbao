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

# KV v2's provider-driven destroy only soft-deletes the current version
# (DELETE on kv/data/*) -- it does not purge kv/metadata/*, so a
# "destroyed" path still shows up in LIST. Report each path's real
# status, and its version count, without ever reading the value itself:
# Terraform's initial scaffold is always exactly version 1 and never
# rewritten (data_json_wo_version never increments), so a path still on
# v1 has never been manually populated -- v2+ means a human has written
# a real value at some point, via a normal put (KV v2 versioning is
# append-only, so a manual write always bumps the version).
path_status() {
  local meta current dtime destroyed
  meta=$(read_json "kv/metadata/homelab/$1")
  current=$(echo "$meta" | jq -r '.data.current_version // empty')
  if [ -z "$current" ] || [ "$current" = "0" ]; then
    echo "no-versions"
    return
  fi
  dtime=$(echo "$meta" | jq -r --arg v "$current" '.data.versions[$v].deletion_time // ""')
  destroyed=$(echo "$meta" | jq -r --arg v "$current" '.data.versions[$v].destroyed // false')
  if [ "$destroyed" = "true" ] || [ -n "$dtime" ]; then
    echo "soft-deleted, v${current}"
  elif [ "$current" = "1" ]; then
    echo "live, v1 (never manually populated)"
  else
    echo "live, v${current} (manually populated at some point)"
  fi
}

walk_kv_keys() {
  local prefix="$1"
  local entry full
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    if [[ "$entry" == */ ]]; then
      walk_kv_keys "${prefix}${entry}"
    else
      full="${prefix}${entry}"
      echo "kv/homelab/${full} [$(path_status "$full")]"
    fi
  done < <(list "kv/metadata/homelab/${prefix}")
}

echo "## Enabled auth methods"
echo
read_json "sys/auth" | jq -r '.data | to_entries[] | "\(.key): \(.value.type)"'
echo

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
    | jq '.data | {bound_service_account_names, bound_service_account_namespaces, token_policies}'
  echo
done < <(list "auth/kubernetes/role")

echo "## AppRole auth roles"
echo
while IFS= read -r role; do
  [ -z "$role" ] && continue
  echo "### $role"
  read_json "auth/approle/role/$role" \
    | jq '.data | {token_policies, token_ttl, token_max_ttl, secret_id_ttl, secret_id_num_uses}'
  echo
done < <(list "auth/approle/role")

echo "## Live tokens carrying a policy with no matching role"
echo
while IFS= read -r accessor; do
  [ -z "$accessor" ] && continue
  info=$(curl -sf -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
    -d "{\"accessor\": \"$accessor\"}" \
    "$VAULT_ADDR/v1/auth/token/lookup-accessor" 2>/dev/null)
  policies=$(echo "$info" | jq -r '.data.policies // [] | join(",")')
  case "$policies" in
    *woodpecker-pipelines* | *certmanager*)
      echo "$info" | jq '.data | {accessor, policies, display_name, creation_time, ttl, expire_time}'
      ;;
  esac
done < <(list "auth/token/accessors")
echo

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
