run "app_backstage_role_reads_its_own_zot_publish_credential_via_its_own_job_service_account" {
  command = plan

  assert {
    condition     = strcontains(local.roles["app-backstage"].policy, "kv/data/homelab/service/k8s-zot/app-backstage/zot-publish")
    error_message = "app-backstage role must grant read on its own dedicated Zot publish credential"
  }
  assert {
    condition     = local.roles["app-backstage"].service_account == "app-backstage-job"
    error_message = "app-backstage role must be bound to its own Kaniko job ServiceAccount, not a shared identity"
  }
}

run "app_backstage_zot_publish_service_credential_scaffolded" {
  command = plan

  assert {
    condition     = contains([for s in local.secrets : "${s.app}/${s.key}"], "service/k8s-zot/app-backstage/zot-publish")
    error_message = "local.secrets must scaffold app-backstage's own dedicated Zot publish credential"
  }
}
