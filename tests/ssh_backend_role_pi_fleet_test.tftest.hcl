run "pi_fleet_ssh_role_scoped_to_pi_fleets_own_use_case" {
  command = plan

  assert {
    condition     = vault_ssh_secret_backend_role.pi_fleet.backend == vault_mount.ssh.path
    error_message = "pi-fleet's role must live on the shared ssh mount"
  }

  assert {
    condition     = vault_ssh_secret_backend_role.pi_fleet.key_type == "ca"
    error_message = "must be a CA-signed role, not OTP or a dynamic key"
  }

  assert {
    condition     = vault_ssh_secret_backend_role.pi_fleet.allow_user_certificates == true
    error_message = "must allow signing user certificates"
  }

  assert {
    condition     = vault_ssh_secret_backend_role.pi_fleet.allowed_users == "pi"
    error_message = "must be scoped to exactly the 'pi' user -- pi-provision's actual SSH user for the whole fleet"
  }

  assert {
    condition     = vault_ssh_secret_backend_role.pi_fleet.max_ttl == "1h"
    error_message = "max_ttl must stay short -- this signs a cert for a one-shot CI connection, not a standing credential"
  }
}
