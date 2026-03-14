# ── SOPS-Secrets ────────────────────────────────────────────
#
# HINWEIS: Die Pfade beziehen sich auf das Repo-Root.
# secrets.yaml liegt in secrets/ und wird für BEIDE Maschinen
# verwendet. Keine manuelle Kopie mehr nötig!
#
# owner/group erst setzen, wenn der zugehörige Dienst aktiv ist.
# Sonst: "unknown user"-Fehler beim Rebuild.
{ config, ... }:

{
  sops = {
    defaultSopsFile = ../../../secrets/secrets.yaml;

    # Entschlüsselung über den SSH-Host-Key des jeweiligen Rechners
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Aktive Secrets (owner/group erst setzen wenn Dienst aktiviert wird!)
      secrets = {
        "nextcloud-admin-pass" = {};
        "vaultwarden-env" = {};
        "netbird-setup-key" = {};
    #   "forgejo-secret" = {};
    #   "paperless-secret-key" = {};
    #   "authentik-secret-key" = {};
    #   "restic-repo-password" = {};
    #   "offsite-backup-password" = {};
     };
  };
}
