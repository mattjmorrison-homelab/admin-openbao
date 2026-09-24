run "argocd_repo_creds_oci_and_image_updater_grant_their_new_per_consumer_zot_credentials" {
  command = plan

  assert {
    condition     = strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/service/k8s-zot/k8s-argocd/zot-pull")
    error_message = "argocd-repo-creds-oci must grant read on its own dedicated Zot pull credential"
  }

  assert {
    condition     = strcontains(local.roles["argocd-image-updater"].policy, "kv/data/homelab/service/k8s-zot/k8s-argocd-image-updater/zot-pull")
    error_message = "argocd-image-updater must grant read on its own dedicated Zot pull credential"
  }

  assert {
    condition     = strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/k8s-argocd/zot-ci-password")
    error_message = "argocd-repo-creds-oci must still keep its old grant during the cutover window -- not repointed live yet"
  }

  assert {
    condition     = strcontains(local.roles["argocd-image-updater"].policy, "kv/data/homelab/k8s-argocd-image-updater/*")
    error_message = "argocd-image-updater must still keep its old grant during the cutover window -- not repointed live yet"
  }
}
