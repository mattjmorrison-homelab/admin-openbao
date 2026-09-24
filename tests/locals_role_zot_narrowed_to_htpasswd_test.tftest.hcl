run "zot_role_reads_only_the_merged_htpasswd_blob" {
  command = plan

  assert {
    condition     = strcontains(local.roles["zot"].policy, "kv/data/homelab/k8s-zot/htpasswd")
    error_message = "zot role must be able to read the merged htpasswd blob its pod actually mounts"
  }

  assert {
    condition     = !strcontains(local.roles["zot"].policy, "service/k8s-zot")
    error_message = "zot's own pod never reads individual consumer passwords -- weaving them into the merged htpasswd blob is exclusively zot-bootstrap's job, not zot's"
  }
}
