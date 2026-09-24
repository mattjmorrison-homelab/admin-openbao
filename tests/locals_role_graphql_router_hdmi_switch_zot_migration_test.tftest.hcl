run "graphql_router_and_hdmi_switch_roles_grant_the_new_per_consumer_zot_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["graphql-router"].policy, "kv/data/homelab/service/k8s-zot/k8s-graphql-router/zot-pull")
    error_message = "graphql-router role must grant read on its own dedicated Zot pull credential"
  }

  assert {
    condition     = strcontains(local.roles["hdmi-switch"].policy, "kv/data/homelab/service/k8s-zot/k8s-hdmi-switch/zot-pull")
    error_message = "hdmi-switch role must grant read on its own dedicated Zot pull credential"
  }

  assert {
    condition     = strcontains(local.roles["graphql-router"].policy, "kv/data/homelab/graphql-router/*")
    error_message = "graphql-router must still keep its old grant during the cutover window -- not repointed live yet"
  }

  assert {
    condition     = strcontains(local.roles["hdmi-switch"].policy, "kv/data/homelab/k8s-hdmi-switch/*")
    error_message = "hdmi-switch must still keep its old grant during the cutover window -- not repointed live yet"
  }
}
