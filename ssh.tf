# ssh.tf
# SSH certificate authority (replacing long-lived SSH private keys stored
# as flat KV secrets): one shared mount signs short-lived certs for
# ephemeral keypairs generated at the moment of use, same shape as the
# "kv" mount serving every KV consumer through its own paths/roles rather
# than a mount per consumer -- pi-fleet is the first consumer, nix-fleet
# is already planned as the next one.
resource "vault_mount" "ssh" {
  path = "ssh"
  type = "ssh"
}

# generate_signing_key defaults to true, but set explicitly: this CA must
# generate its own keypair internally, never take external key material.
resource "vault_ssh_secret_backend_ca" "shared" {
  backend              = vault_mount.ssh.path
  generate_signing_key = true
  key_type             = "ed25519"
}

# pi-fleet's CI signs an ephemeral keypair's public half here instead of
# fetching a long-lived private key. allowed_users = "pi" matches
# pi-provision's actual SSH user for the whole Pi fleet (fleet.yaml:
# every ssh_host is "pi@<name>.local"). Short ttl/max_ttl: this signs a
# cert for one CI SSH session, not a standing credential.
resource "vault_ssh_secret_backend_role" "pi_fleet" {
  backend                 = vault_mount.ssh.path
  name                    = "pi-fleet"
  key_type                = "ca"
  allow_user_certificates = true
  allowed_users           = "pi"
  default_user            = "pi"
  ttl                     = "5m"
  max_ttl                 = "1h"
}
