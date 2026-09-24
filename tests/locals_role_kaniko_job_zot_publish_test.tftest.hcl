run "kaniko_job_roles_read_their_own_zot_publish_credential_via_their_own_job_service_account" {
  command = plan

  assert {
    condition     = strcontains(local.roles["graph-router"].policy, "kv/data/homelab/service/k8s-zot/graph-router/zot-publish")
    error_message = "graph-router role must grant read on its own dedicated Zot publish credential"
  }
  assert {
    condition     = local.roles["graph-router"].service_account == "graph-router-job"
    error_message = "graph-router role must be bound to its own Kaniko job ServiceAccount, not a shared identity"
  }

  assert {
    condition     = strcontains(local.roles["graph-hdmi-switch"].policy, "kv/data/homelab/service/k8s-zot/graph-hdmi-switch/zot-publish")
    error_message = "graph-hdmi-switch role must grant read on its own dedicated Zot publish credential"
  }
  assert {
    condition     = local.roles["graph-hdmi-switch"].service_account == "graph-hdmi-switch-job"
    error_message = "graph-hdmi-switch role must be bound to its own Kaniko job ServiceAccount, not a shared identity"
  }

  assert {
    condition     = strcontains(local.roles["ui-hdmi-switch"].policy, "kv/data/homelab/service/k8s-zot/ui-hdmi-switch/zot-publish")
    error_message = "ui-hdmi-switch role must grant read on its own dedicated Zot publish credential"
  }
  assert {
    condition     = local.roles["ui-hdmi-switch"].service_account == "ui-hdmi-switch-job"
    error_message = "ui-hdmi-switch role must be bound to its own Kaniko job ServiceAccount, not a shared identity"
  }
}
