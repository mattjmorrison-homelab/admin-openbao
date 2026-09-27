run "app_backstage_discord_role_reads_only_its_own_webhook_path" {
  command = plan

  assert {
    condition     = strcontains(local.roles["app-backstage-discord"].policy, "kv/data/homelab/service/admin-discord/app-backstage/webhook-url")
    error_message = "app-backstage-discord must grant read on app-backstage's dedicated webhook path"
  }
  assert {
    condition     = local.roles["app-backstage-discord"].service_account == "github-runner-workload"
    error_message = "app-backstage-discord must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }
}

run "admin_discord_webhooks_role_writes_app_backstage_path_too" {
  command = plan

  assert {
    condition     = strcontains(local.roles["admin-discord-webhooks"].policy, "kv/data/homelab/service/admin-discord/app-backstage/webhook-url")
    error_message = "admin-discord-webhooks must grant create/update on app-backstage's dedicated webhook path"
  }
}

run "app_backstage_webhook_service_credential_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "service/admin-discord/app-backstage/webhook-url")
    error_message = "local.secrets must scaffold app-backstage's dedicated webhook-url credential"
  }
}

run "backstage_role_also_reads_its_own_zot_pull_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["backstage"].policy, "kv/data/homelab/service/k8s-zot/k8s-backstage/zot-pull")
    error_message = "backstage role must grant read on its own dedicated zot-pull credential"
  }
  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "service/k8s-zot/k8s-backstage/zot-pull")
    error_message = "local.secrets must scaffold k8s-backstage's zot-pull credential"
  }
}
