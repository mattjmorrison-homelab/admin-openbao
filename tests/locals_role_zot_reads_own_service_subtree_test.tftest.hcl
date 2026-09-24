run "zot_role_can_read_its_own_service_subtree" {
  command = plan

  assert {
    condition     = strcontains(local.roles["zot"].policy, "kv/data/homelab/k8s-zot/htpasswd")
    error_message = "zot role must be able to read the merged htpasswd blob its pod actually mounts"
  }

  assert {
    condition     = strcontains(local.roles["zot"].policy, "kv/data/homelab/service/k8s-zot/*")
    error_message = "zot role must be able to read its own service/k8s-zot/* subtree -- confirmed live (2026-09-24) that all 9 per-consumer service-credential ExternalSecrets authenticate via this same role, not just the zot pod's own htpasswd ExternalSecret"
  }
}
