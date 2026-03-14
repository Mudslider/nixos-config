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
    serviceConfig = {
      Type = "oneshot";

      # HDDs gestaffelt aufwecken (verhindert Stromspitzen beim gleichzeitigen Spinup)
      ExecStartPre = pkgs.writeShellScript "wake-hdds" ''
        echo "Wecke HDDs gestaffelt auf..."
        for disk in /dev/disk/by-id/ata-WDC_WD*; do
          # Partitionen überspringen (nur Basis-Geräte aufwecken)
          [[ "$disk" == *-part* ]] && continue
          if [ -b "$disk" ]; then
            ${pkgs.hdparm}/bin/hdparm -C "$disk" || true
            echo "Warte 8 Sekunden vor nächster HDD..."
            sleep 8
          fi
        done
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
