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

    # TEMPORÄR DEAKTIVIERT — erst nach Anleitung 02 einkommentieren
      secrets = {
    #   "nextcloud-admin-pass" = {};  # owner/group erst setzen wenn Dienst aktiv!
        "vaultwarden-env" = {};
    #   "forgejo-secret" = {};        # owner/group erst setzen wenn Dienst aktiv!
    #   "paperless-secret-key" = {};
    #   "authentik-secret-key" = {};
    #   "restic-repo-password" = {};
    #   "offsite-backup-password" = {};
     };
  };
}
