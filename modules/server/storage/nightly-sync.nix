{ pkgs, ... }:

{
  # ── Nächtlicher Sync: SSD → ZFS-Pool (HDD) ───────────────

  systemd.services.nightly-sync = {
    description = "SSD-Buffer auf ZFS-HDD synchronisieren";
    serviceConfig = {
      Type = "oneshot";

      # HDDs gestaffelt aufwecken
      ExecStartPre = pkgs.writeShellScript "wake-hdds" ''
        echo "Wecke HDDs gestaffelt auf..."
        # Erste HDD aufwecken (Lesezugriff reicht)
        for disk in /dev/disk/by-id/ata-WDC_WD*; do
          if [ -b "$disk" ]; then
            ${pkgs.hdparm}/bin/hdparm -C "$disk" || true
            echo "Warte 8 Sekunden vor nächster HDD..."
            sleep 8
          fi
        done
        # Warte bis HDDs bereit sind
        sleep 5
      '';

      ExecStart = pkgs.writeShellScript "sync-to-hdd" ''
        set -euo pipefail

        echo "=== Starte nächtlichen Sync: $(date) ==="

        # ── Fotos: Move-Pattern ─────────────────────────
        # SSD = Eingangs-Puffer, HDD = wachsendes Archiv
        if [ -d "/srv/ssd-buffer/photos/" ] && [ "$(ls -A /srv/ssd-buffer/photos/ 2>/dev/null)" ]; then
          echo "Verschiebe Fotos auf HDD..."
          ${pkgs.rsync}/bin/rsync -avh --remove-source-files \
            /srv/ssd-buffer/photos/ /tank/photos/
          ${pkgs.coreutils}/bin/find /srv/ssd-buffer/photos/ -type d -empty -delete 2>/dev/null || true
        fi

        # ── Dokumente: Move-Pattern ─────────────────────
        if [ -d "/srv/ssd-buffer/documents/" ] && [ "$(ls -A /srv/ssd-buffer/documents/ 2>/dev/null)" ]; then
          echo "Verschiebe Dokumente auf HDD..."
          ${pkgs.rsync}/bin/rsync -avh --remove-source-files \
            /srv/ssd-buffer/documents/ /tank/documents/
          ${pkgs.coreutils}/bin/find /srv/ssd-buffer/documents/ -type d -empty -delete 2>/dev/null || true
        fi

        # ── Backup: Nur spiegeln ────────────────────────
        # Restic verwaltet sein Repository selbst.
        # Kein --delete, kein --remove-source-files!
        if [ -d "/srv/ssd-buffer/backup/" ] && [ "$(ls -A /srv/ssd-buffer/backup/ 2>/dev/null)" ]; then
          echo "Spiegle Backup-Repository auf HDD..."
          ${pkgs.rsync}/bin/rsync -avh \
            /srv/ssd-buffer/backup/ /tank/backup/
        fi

        echo "=== Sync abgeschlossen: $(date) ==="
      '';
    };
  };

  systemd.timers.nightly-sync = {
    description = "Nächtlicher SSD→HDD Sync Timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00"; # 3 Uhr nachts
      Persistent = true;              # Nachholen bei verpasstem Timer
      RandomizedDelaySec = "5m";      # Leichte Streuung
    };
  };
}
