run "argocd_repo_creds_oci_and_image_updater_roles_scoped_to_only_the_new_per_consumer_zot_credential" {
  command = plan

  assert {
    condition     = strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/service/k8s-zot/k8s-argocd/zot-pull")
    error_message = "argocd-repo-creds-oci role must grant read on its own dedicated Zot pull credential"
  }

  assert {
    condition     = strcontains(local.roles["argocd-image-updater"].policy, "kv/data/homelab/service/k8s-zot/k8s-argocd-image-updater/zot-pull")
    error_message = "argocd-image-updater role must grant read on its own dedicated Zot pull credential"
  }

  assert {
    condition     = !strcontains(local.roles["argocd-repo-creds-oci"].policy, "kv/data/homelab/k8s-argocd/zot-ci-password")
    error_message = "argocd-repo-creds-oci's old zot-ci-password grant must be gone -- migration confirmed live, nothing else references it"
  }

  assert {
    condition     = !strcontains(local.roles["argocd-image-updater"].policy, "kv/data/homelab/k8s-argocd-image-updater/*")
    error_message = "argocd-image-updater's old bare/k8s-argocd-image-updater/* grant must be gone -- migration confirmed live, nothing else references it"
  }
}
