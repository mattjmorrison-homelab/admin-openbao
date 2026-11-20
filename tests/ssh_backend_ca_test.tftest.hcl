run "ssh_mount_is_a_single_shared_backend" {
  command = plan

  assert {
    condition     = vault_mount.ssh.path == "ssh"
    error_message = "the SSH secrets engine must be mounted at path 'ssh'"
  }

  assert {
    condition     = vault_mount.ssh.type == "ssh"
    error_message = "the mount must be of type 'ssh'"
  }
}

run "ssh_ca_generates_its_own_keypair" {
  command = plan

  assert {
    condition     = vault_ssh_secret_backend_ca.shared.generate_signing_key == true
    error_message = "the CA must generate its own signing key internally, not take external key material"
  }

  assert {
    condition     = vault_ssh_secret_backend_ca.shared.backend == vault_mount.ssh.path
    error_message = "the CA must live on the shared ssh mount"
  }
}
