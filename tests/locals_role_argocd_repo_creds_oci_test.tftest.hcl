run "argocd_repo_creds_oci_policy_grants_only_its_own_exact_key" {
  command = plan

  assert {
    condition     = strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/k8s-argocd/zot-ci-password")
    error_message = "argocd-repo-creds-oci policy must grant its own exact key, k8s-argocd/zot-ci-password"
  }

  assert {
    condition     = !strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/k8s-argocd/*")
    error_message = "argocd-repo-creds-oci policy must not grant the k8s-argocd/* wildcard -- it should only read its own key, not discord-webhook-url or github-webhook-secret too"
  }
}
