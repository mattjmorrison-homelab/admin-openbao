# ssh.tf
resource "vault_mount" "ssh" {
  path = "ssh"
  type = "ssh"
}

# Set explicitly (matches the default) to assert this CA never imports
# external key material.
resource "vault_ssh_secret_backend_ca" "shared" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
  key_type             = "ed25519"
}

# allowed_users = "pi" matches pi-provision's SSH user for the whole
# fleet (fleet.yaml: every ssh_host is "pi@<name>.local").
resource "vault_ssh_secret_backend_role" "pi_fleet" {
  backend                 = vault_mount.ssh.path
  name                    = "pi-fleet"
  key_type                = "ca"
  allow_user_certificates = true
  allowed_users           = "pi"
  default_user            = "pi"
  ttl                     = "5m"
  max_ttl                 = "1h"

  # Without these, certs carry zero extensions -- pi-health's deploy flow
  # uses `ssh -t`, which fails PTY allocation on a cert with no permit-pty.
  default_extensions = {
    "permit-pty"              = ""
    "permit-port-forwarding"  = ""
    "permit-agent-forwarding" = ""
    "permit-user-rc"          = ""
  }
}
