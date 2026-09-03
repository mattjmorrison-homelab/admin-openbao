run "zot_role_can_read_its_own_service_subtree" {
  command = plan

  assert {
    condition     = strcontains(local.roles["zot"].policy, "kv/data/homelab/service/k8s-zot/*")
    error_message = "zot role must be able to read its own service/k8s-zot/* subtree, to weave generated consumer credentials into the rendered htpasswd"
  }
}
