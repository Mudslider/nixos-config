{ config, pkgs, ... }:

{
  # ── Offsite-Backup: Server → Freund (über NetBird) ────────
  #
  # Sichert alle kritischen Server-Daten auf den Server deines Freundes.
  # Transport: SFTP über NetBird-VPN (WireGuard-verschlüsselt).
  # Daten: Restic-verschlüsselt (AES-256, Passwort bleibt lokal).
  #
  # Was gesichert wird:
  #   - Nextcloud-Datenbank (PostgreSQL Dump)
  #   - Vaultwarden-DB + Backup
  #   - Forgejo-Repositories + DB
  #   - PaperlessNGX-Daten + Medien
  #   - Authentik-Datenbank (PostgreSQL Dump aus Container)
  #   - Home Assistant Config
  #   - Uptime Kuma Daten
  #   - NixOS-Konfiguration
  #   - sops-Secrets (verschlüsselt)
  #
  # Voraussetzungen auf dem Server des Freundes:
  #   - SSH-Zugang (z.B. User "backup-philip") per Key-Auth
  #   - Verzeichnis für Backups (z.B. /backup/philip/)
  #   - Erreichbar über NetBird-IP (z.B. 100.64.0.2)

  # ── Pre-Backup: Datenbank-Dumps ───────────────────────────
  systemd.services.offsite-backup-pre = {
    description = "Datenbank-Dumps für Offsite-Backup";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "backup-dump-dbs" ''
        set -euo pipefail
        DUMP_DIR="/srv/ssd-buffer/services/db-dumps"
        mkdir -p "$DUMP_DIR"

        echo "=== Datenbank-Dumps: $(date) ==="

        # Nextcloud (PostgreSQL, läuft nativ)
        echo "Dumping Nextcloud DB..."
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/pg_dump nextcloud \
          > "$DUMP_DIR/nextcloud.sql" 2>/dev/null || echo "WARN: Nextcloud-Dump fehlgeschlagen"

        # Authentik (PostgreSQL im Container)
        echo "Dumping Authentik DB..."
        ${pkgs.podman}/bin/podman exec authentik-postgres \
          pg_dump -U authentik authentik \
          > "$DUMP_DIR/authentik.sql" 2>/dev/null || echo "WARN: Authentik-Dump fehlgeschlagen"

        # Immich (PostgreSQL im Container)
        echo "Dumping Immich DB..."
        ${pkgs.podman}/bin/podman exec immich-postgres \
          pg_dump -U immich immich \
          > "$DUMP_DIR/immich.sql" 2>/dev/null || echo "WARN: Immich-Dump fehlgeschlagen"

        echo "=== Dumps abgeschlossen ==="
        ls -lh "$DUMP_DIR/"
      '';
    };
  };

  # ── Restic Offsite-Backup ─────────────────────────────────
  systemd.services.offsite-backup = {
    description = "Offsite-Backup zum Freund (über NetBird)";
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "offsite-backup-pre.service"   # DB-Dumps zuerst
      "nightly-sync.service"          # Nach dem SSD→HDD Sync
    ];
    requires = [ "offsite-backup-pre.service" ];

    environment = {
      # TODO: Ersetze mit der NetBird-IP und dem SSH-User beim Freund
      RESTIC_REPOSITORY = "sftp:backup-philip@100.64.0.2:/backup/philip";
    };

    serviceConfig = {
      Type = "oneshot";
      # Restic-Passwort aus sops-nix
      EnvironmentFile = ""; # Placeholder
      ExecStart = pkgs.writeShellScript "offsite-backup" ''
        set -euo pipefail
        export RESTIC_PASSWORD_FILE="/run/secrets/offsite-backup-password"

        echo "=== Offsite-Backup Start: $(date) ==="

        # ── Backup ausführen ────────────────────────────
        ${pkgs.restic}/bin/restic backup \
          --verbose \
          --one-file-system \
          --exclude-caches \
          --tag "automatic" \
          \
          /srv/ssd-buffer/services/db-dumps/ \
          /srv/ssd-buffer/services/vaultwarden/ \
          /srv/ssd-buffer/services/forgejo/ \
          /srv/ssd-buffer/services/paperless/ \
          /srv/ssd-buffer/services/hass/ \
          /srv/ssd-buffer/services/uptime-kuma/ \
          /srv/ssd-buffer/services/navidrome/ \
          /srv/ssd-buffer/services/authentik/ \
          /home/philip/nixos-homeserver/ \
          \
          --exclude "/srv/ssd-buffer/services/forgejo/data/tmp" \
          --exclude "/srv/ssd-buffer/services/paperless/data/index" \
          --exclude "*.log" \
          --exclude "*.cache"

        echo "=== Aufräumen ==="

        # ── Alte Snapshots entfernen ────────────────────
        ${pkgs.restic}/bin/restic forget \
          --keep-daily 7 \
          --keep-weekly 4 \
          --keep-monthly 6 \
          --prune

        # ── Integrität prüfen (1× pro Woche Sonntags) ──
        if [ "$(date +%u)" = "7" ]; then
          echo "Sonntag: Starte Integritätsprüfung..."
          ${pkgs.restic}/bin/restic check
        fi

        echo "=== Offsite-Backup Ende: $(date) ==="
      '';

      # Timeout: Großes erstes Backup kann lange dauern
      TimeoutStartSec = "6h";

      # Bei Fehler nicht sofort neu versuchen
      Restart = "no";
    };
  };

  systemd.timers.offsite-backup = {
    description = "Tägliches Offsite-Backup zum Freund";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00"; # 4 Uhr nachts (nach nightly-sync um 3 Uhr)
      Persistent = true;              # Nachholen bei verpasstem Timer
      RandomizedDelaySec = "10m";
    };
  };

  # ── Dump-Verzeichnis ──────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /srv/ssd-buffer/services/db-dumps 0750 root root -"
  ];

  # ── SSH-Key für den Backup-Zugang beim Freund ─────────────
  # Erstelle einen dedizierten Key:
  #   sudo ssh-keygen -t ed25519 -f /root/.ssh/offsite-backup -N "" -C "homeserver-backup"
  #   → Public Key an den Freund schicken
  #   → Er trägt ihn in ~backup-philip/.ssh/authorized_keys ein
  #
  # Restic braucht den Key in der SSH-Config:
  programs.ssh.extraConfig = ''
    Host 100.64.0.2
      IdentityFile /root/.ssh/offsite-backup
      User backup-philip
      StrictHostKeyChecking accept-new
  '';
}
