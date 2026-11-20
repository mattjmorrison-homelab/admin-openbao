run "alertmanager_role_also_reads_new_admin_discord_path" {
  command = plan

  assert {
    condition     = strcontains(local.roles["alertmanager"].policy, "kv/data/homelab/service/admin-discord/k8s-alertmanager/*")
    error_message = "alertmanager must grant read on the new service/admin-discord/k8s-alertmanager/* wildcard"
  }

  assert {
    condition     = strcontains(local.roles["alertmanager"].policy, "kv/data/homelab/k8s-alertmanager/*")
    error_message = "alertmanager must keep its existing read grant on the old k8s-alertmanager/* wildcard unchanged"
  }
}
