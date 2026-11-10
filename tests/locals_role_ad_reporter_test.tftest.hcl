run "k8s_ad_reporter_role_reads_its_own_zot_pull_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["k8s-ad-reporter"].policy, "kv/data/homelab/service/k8s-zot/k8s-ad-reporter/zot-pull")
    error_message = "k8s-ad-reporter role must grant read on its own dedicated Zot pull credential"
  }
  assert {
    condition     = local.roles["k8s-ad-reporter"].namespace == "ad-reporter" && local.roles["k8s-ad-reporter"].service_account == "ad-reporter"
    error_message = "k8s-ad-reporter role must bind to the ad-reporter namespace/ServiceAccount"
  }
}

run "graph_and_ui_ad_reporter_roles_read_their_own_zot_publish_credential_via_their_own_job_service_account" {
  command = plan

  assert {
    condition     = strcontains(local.roles["graph-ad-reporter"].policy, "kv/data/homelab/service/k8s-zot/graph-ad-reporter/zot-publish")
    error_message = "graph-ad-reporter role must grant read on its own dedicated Zot publish credential"
  }
  assert {
    condition     = local.roles["graph-ad-reporter"].service_account == "graph-ad-reporter-job"
    error_message = "graph-ad-reporter role must be bound to its own Kaniko job ServiceAccount, not a shared identity"
  }

  assert {
    condition     = strcontains(local.roles["ui-ad-reporter"].policy, "kv/data/homelab/service/k8s-zot/ui-ad-reporter/zot-publish")
    error_message = "ui-ad-reporter role must grant read on its own dedicated Zot publish credential"
  }
  assert {
    condition     = local.roles["ui-ad-reporter"].service_account == "ui-ad-reporter-job"
    error_message = "ui-ad-reporter role must be bound to its own Kaniko job ServiceAccount, not a shared identity"
  }
}

run "graph_and_ui_ad_reporter_discord_roles_read_only_their_own_webhook_path" {
  command = plan

  assert {
    condition     = strcontains(local.roles["graph-ad-reporter-discord"].policy, "kv/data/homelab/service/admin-discord/graph-ad-reporter/webhook-url")
    error_message = "graph-ad-reporter-discord must grant read on graph-ad-reporter's dedicated webhook path"
  }
  assert {
    condition     = local.roles["graph-ad-reporter-discord"].service_account == "github-runner-workload"
    error_message = "graph-ad-reporter-discord must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }

  assert {
    condition     = strcontains(local.roles["ui-ad-reporter-discord"].policy, "kv/data/homelab/service/admin-discord/ui-ad-reporter/webhook-url")
    error_message = "ui-ad-reporter-discord must grant read on ui-ad-reporter's dedicated webhook path"
  }
  assert {
    condition     = local.roles["ui-ad-reporter-discord"].service_account == "github-runner-workload"
    error_message = "ui-ad-reporter-discord must bind to the shared github-runner-workload CI identity, matching the per-purpose-role convention"
  }
}

run "ad_reporter_service_credentials_scaffolded" {
  command = plan

  assert {
    condition = alltrue([
      for path in [
        "service/k8s-zot/graph-ad-reporter/zot-publish",
        "service/k8s-zot/ui-ad-reporter/zot-publish",
        "service/k8s-zot/k8s-ad-reporter/zot-pull",
        "service/admin-discord/graph-ad-reporter/webhook-url",
        "service/admin-discord/ui-ad-reporter/webhook-url",
        "service/admin-discord/k8s-ad-reporter/confirmed-webhook-url",
        "service/admin-discord/k8s-ad-reporter/suspicious-webhook-url",
      ] :
      contains([for s in local.secrets : "${s.app}/${s.key}"], path)
    ])
    error_message = "local.secrets must scaffold all 7 ad-reporter service-credential paths"
  }
}
