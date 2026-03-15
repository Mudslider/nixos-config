{ config, pkgs, lib, ... }:

let
  # ── Backup-Repo-Liste ──────────────────────────────────────
  # Neue Maschine hinzufügen:
  #   1. Eintrag hier mit ssdPath, hddPath, secretName
  #   2. SOPS-Secret anlegen: sops secrets/secrets.yaml
  #   3. Secret in modules/server/security/encryption.nix aktivieren
  backupRepos = [
    {
      name       = "windows (Praxis_NUC)";
      ssdPath    = "/srv/ssd-buffer/backup";
      hddPath    = "/tank/backup";
      secretName = "restic-password-windows";
    }
    {
      name       = "polly";
      ssdPath    = "/srv/ssd-buffer/backup/polly";
      hddPath    = "/tank/backup/polly";
      secretName = "restic-password-polly";
    }
    {
      name       = "nora";
      ssdPath    = "/srv/ssd-buffer/backup/nora";
      hddPath    = "/tank/backup/nora";
      secretName = "restic-password-nora";
    }
    {
      name       = "berlin (Bruder)";
      ssdPath    = "/srv/ssd-buffer/backup/berlin";
      hddPath    = "/tank/backup/berlin";
      secretName = "restic-password-berlin";
    }
  ];

  # Generiert Tiering-Block pro Repo (wird in ExecStart eingebettet)
  mkTierBlock = repo:
    let pw = config.sops.secrets.${repo.secretName}.path;
    in ''
      echo "--- Tiering: ${repo.name} ---"
      if [ ! -d "${repo.ssdPath}" ]; then
        echo "Überspringe ${repo.name}: Verzeichnis fehlt"
      else
        mkdir -p "${repo.hddPath}"

        # HDD-Repo initialisieren falls noch nicht vorhanden
        if ! RESTIC_PASSWORD_FILE="${pw}" \
            ${pkgs.restic}/bin/restic -r "${repo.hddPath}" cat config >/dev/null 2>&1; then
          echo "Initialisiere HDD-Repo ${repo.name}..."
          RESTIC_PASSWORD_FILE="${pw}" \
            ${pkgs.restic}/bin/restic -r "${repo.hddPath}" init
        fi

        # Neue Snapshots SSD → HDD kopieren (idempotent, bereits kopierte werden übersprungen)
        # Syntax: -r = Ziel (HDD), --from-repo = Quelle (SSD)
        echo "Kopiere Snapshots ${repo.name}: SSD→HDD..."
        RESTIC_PASSWORD_FILE="${pw}" \
        RESTIC_FROM_PASSWORD_FILE="${pw}" \
          ${pkgs.restic}/bin/restic -r "${repo.hddPath}" copy --from-repo "${repo.ssdPath}"

        # SSD bereinigen: nur letzten ~Tag behalten, Rest ist auf HDD
        echo "Bereinige SSD-Repo ${repo.name}..."
        RESTIC_PASSWORD_FILE="${pw}" \
          ${pkgs.restic}/bin/restic -r "${repo.ssdPath}" forget --keep-within 26h --prune

        echo "Fertig: ${repo.name}"
      fi
    '';

in
{
  # ── Nächtlicher Sync: SSD → ZFS-Pool (HDD) ───────────────
  # Design-Prinzip: HDDs fahren nur einmal pro Nacht hoch.
  # Daten akkumulieren tagsüber auf SSD, werden um 3 Uhr übergeben.
  # HDDs schlafen danach bis zur nächsten Nacht.

  systemd.services.nightly-sync = {
    description = "SSD-Buffer auf ZFS-HDD synchronisieren";
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
    serviceConfig = {
      Type = "oneshot";

      # HDDs gestaffelt aufwecken (verhindert Stromspitzen beim gleichzeitigen Spinup)
      # Erkennt ZFS-Pool-Devices automatisch statt Hersteller-Glob
      ExecStartPre = pkgs.writeShellScript "wake-hdds" ''
        echo "Wecke HDDs gestaffelt auf..."
        for disk in $(${pkgs.zfs}/bin/zpool list -vHP tank 2>/dev/null | ${pkgs.gawk}/bin/awk '/\/dev\/disk/ {print $1}'); do
          # Nur Basis-Geräte (Partitionen → Parent-Device auflösen)
          base=$(echo "$disk" | ${pkgs.gnused}/bin/sed 's/-part[0-9]*$//')
          if [ -b "$base" ]; then
            echo "Wecke $base auf..."
            ${pkgs.hdparm}/bin/hdparm -C "$base" || true
            echo "Warte 8 Sekunden vor nächster HDD..."
            sleep 8
          fi
        done
        sleep 5
      '';

      ExecStart = pkgs.writeShellScript "sync-to-hdd" ''
        set -euo pipefail

        echo "=== Starte nächtlichen Sync: $(date) ==="

        # ── Fotos: Copy + Age-Out ──────────────────────
        # SSD = schneller Zugriff auf aktuelle Fotos (letzte 90 Tage)
        # HDD = vollständiges Archiv
        # 1. Alles auf HDD kopieren (rsync ist idempotent, keine Duplikate)
        # 2. Dateien >90 Tage nur von der SSD löschen (HDD behält alles)
        if [ -d "/srv/ssd-buffer/photos/" ] && [ "$(ls -A /srv/ssd-buffer/photos/ 2>/dev/null)" ]; then
          echo "Kopiere Fotos auf HDD (ohne SSD-Löschung)..."
          ${pkgs.rsync}/bin/rsync -avh \
            /srv/ssd-buffer/photos/ /tank/photos/

          echo "Bereinige Fotos älter als 90 Tage von SSD..."
          ${pkgs.coreutils}/bin/find /srv/ssd-buffer/photos/ -type f -mtime +90 -delete 2>/dev/null || true
          ${pkgs.coreutils}/bin/find /srv/ssd-buffer/photos/ -type d -empty -delete 2>/dev/null || true
        fi

        # ── Paperless: Copy-Backup auf HDD ────────────
        # Paperless-Daten bleiben auf SSD (schneller Zugriff).
        # Nächtliches rsync-Backup auf HDD als Schutz bei SSD-Ausfall.
        # KEIN --remove-source-files! Consume-Ordner darf nicht geleert werden.
        echo "Sichere Paperless-Daten auf HDD..."
        mkdir -p /tank/paperless-backup
        ${pkgs.rsync}/bin/rsync -avh \
          /srv/ssd-buffer/services/paperless/ /tank/paperless-backup/services/
        ${pkgs.rsync}/bin/rsync -avh \
          /srv/ssd-buffer/documents/ /tank/paperless-backup/consume/

        # ── Immich Thumbnails: SSD→HDD Backup ──────
        # Thumbnails leben auf SSD für schnelles Browsen.
        # Backup auf HDD für den Fall eines SSD-Ausfalls.
        if [ -d "/srv/ssd-buffer/immich-thumbs/" ]; then
          echo "Sichere Immich-Thumbnails auf HDD..."
          ${pkgs.rsync}/bin/rsync -avh \
            /srv/ssd-buffer/immich-thumbs/ /tank/photos/thumbs-backup/
        fi

        # ── Backup-Tiering: SSD→HDD kopieren + SSD bereinigen ──
        # Restic copy ist idempotent: bereits kopierte Snapshots werden übersprungen.
        # Nach dem Kopieren bleiben nur die letzten ~26h auf der SSD.
        echo "=== Backup-Tiering ==="
        ${lib.concatMapStrings mkTierBlock backupRepos}

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
