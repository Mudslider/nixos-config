{ config, pkgs, ... }:

{
  # ── Offsite-Backup: Homeserver → berlinas (Bruder, Berlin) ───
  #
  # Transport: SFTP über NetBird-VPN (Ende-zu-Ende verschlüsselt).
  # Daten: Restic-verschlüsselt (AES-256, Passwort bleibt lokal).
  #
  # Was gesichert wird:
  #   - Vaultwarden-Daten
  #   - PaperlessNGX-Daten + Medien
  #   - Immich-Datenbank (PostgreSQL Dump — Fotos bleiben lokal)
  #   - NixOS-Konfiguration
  #   - sops-Secrets (bereits verschlüsselt)
  #
  # Voraussetzungen auf berlinas (einmalig):
  #   1. User anlegen:   adduser backup-philip
  #   2. Verzeichnis:    mkdir -p /backup/philip && chown backup-philip /backup/philip
  #   3. SSH-Key:        Public Key von /root/.ssh/offsite-backup.pub eintragen
  #      → ~backup-philip/.ssh/authorized_keys
  #
  # SSH-Key generieren (einmalig auf dem Homeserver):
  #   sudo ssh-keygen -t ed25519 -f /root/.ssh/offsite-backup -N "" -C "homeserver-offsite"
  #   sudo cat /root/.ssh/offsite-backup.pub  → an Bruder schicken

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

        # Immich (PostgreSQL im Container)
        echo "Dumping Immich DB..."
        ${pkgs.podman}/bin/podman exec immich-postgres \
          pg_dump -U immich immich \
          > "$DUMP_DIR/immich.sql" 2>/dev/null || echo "WARN: Immich-Dump fehlgeschlagen (läuft der Container?)"

        echo "=== Dumps abgeschlossen ==="
        ls -lh "$DUMP_DIR/"
      '';
    };
  };

  # ── Restic Offsite-Backup ─────────────────────────────────
  systemd.services.offsite-backup = {
    description = "Offsite-Backup zu berlinas (Bruder, Berlin)";
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "offsite-backup-pre.service"   # DB-Dumps zuerst
      "nightly-sync.service"          # Nach dem SSD→HDD Sync
    ];
    requires = [ "offsite-backup-pre.service" ];

    environment = {
      RESTIC_REPOSITORY = "sftp:backup-philip@100.95.39.77:/backup/philip";
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "offsite-backup" ''
        set -euo pipefail
        export RESTIC_PASSWORD_FILE="${config.sops.secrets."offsite-backup-password".path}"

        echo "=== Offsite-Backup Start: $(date) ==="

        # Repo initialisieren falls neu
        if ! restic cat config >/dev/null 2>&1; then
          echo "Initialisiere Offsite-Repo..."
          restic init
        fi

        # ── Backup ausführen ────────────────────────────
        ${pkgs.restic}/bin/restic backup \
          --verbose \
          --one-file-system \
          --exclude-caches \
          --tag "automatic" \
          \
          /srv/ssd-buffer/services/db-dumps/ \
          /srv/ssd-buffer/services/vaultwarden/ \
          /srv/ssd-buffer/services/paperless/ \
          /home/philip/nixos-config/ \
          /etc/sops/ \
          \
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

      TimeoutStartSec = "6h";
      Restart = "no";
    };
  };

  systemd.timers.offsite-backup = {
    description = "Tägliches Offsite-Backup zu berlinas";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 04:00:00"; # 4 Uhr nachts (nach nightly-sync um 3 Uhr)
      Persistent = true;
      RandomizedDelaySec = "10m";
    };
  };

  # ── Dump-Verzeichnis ──────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /srv/ssd-buffer/services/db-dumps 0750 root root -"
  ];

  # ── SSH-Config für berlinas ───────────────────────────────
  programs.ssh.extraConfig = ''
    Host 100.95.39.77
      IdentityFile /root/.ssh/offsite-backup
      User backup-philip
      StrictHostKeyChecking accept-new
  '';
}
