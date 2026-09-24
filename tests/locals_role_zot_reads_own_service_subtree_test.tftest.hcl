run "zot_role_scoped_to_only_its_own_htpasswd_now_the_shared_delivery_mechanism_is_gone" {
  command = plan

  assert {
    condition     = strcontains(local.roles["zot"].policy, "kv/data/homelab/k8s-zot/htpasswd")
    error_message = "zot role must be able to read the merged htpasswd blob its pod actually mounts"
  }

  assert {
    condition     = !strcontains(local.roles["zot"].policy, "kv/data/homelab/service/k8s-zot/*")
    error_message = "zot role must not grant service/k8s-zot/* anymore -- k8s-zot#14 removed the last consumer of this role that needed it (the now-fully-unused zot-service-cred-* delivery mechanism); every real consumer now reads its own dedicated path via its own role"
  }
}
