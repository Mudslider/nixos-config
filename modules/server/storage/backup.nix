{ config, pkgs, ... }:

{
  # ── Restic REST-Server ────────────────────────────────────
  # Performanter als SFTP, unterstützt Append-Only-Modus
  services.restic.server = {
    enable = true;
    listenAddress = "100.95.103.67:8100"; # NetBird-Interface — nur über VPN erreichbar
    dataDir = "/srv/ssd-buffer/backup";
    appendOnly = true; # Ransomware-Schutz: nur Anhängen, kein Löschen
  };

  # ── Samba-Share für Heimnetz-Zugriff ──────────────────────
  # Für den Fall, dass du von zu Hause auf Backup-Daten zugreifen musst
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        security = "user";
        "server string" = "Homeserver";
        "bind interfaces only" = "yes";
        interfaces = "lo enp1s0"; # Nur lokales Interface, NICHT NetBird
        "server min protocol" = "SMB3_00";
        # Gast-Zugang deaktivieren
        "map to guest" = "never";
      };
      media = {
        path = "/tank/media";
        "valid users" = "philip";
        "read only" = "yes";
        browseable = "yes";
        comment = "Medien (Jellyfin/Immich/Navidrome)";
      };
      backup = {
        path = "/tank/backup";
        "valid users" = "philip";
        "read only" = "yes"; # Schreibschutz!
        browseable = "yes";
        comment = "Arbeitsrechner-Backup (nur lesen)";
      };
    };
  };

  # Samba-Passwort muss separat gesetzt werden:
  # sudo smbpasswd -a philip

  # ── Restic Prune (einkommentieren nach erstem Backup) ─────
  # Räumt alte Snapshots auf. Nur auf dem Server möglich,
  # da der REST-Server im Append-Only-Modus läuft.
  # Siehe Anleitung 15-backup.md
  #
  # systemd.services.restic-prune = {
  #   description = "Restic Repository aufräumen";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.restic}/bin/restic -r /srv/ssd-buffer/backup/ forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune --password-file /run/secrets/restic-repo-password";
  #   };
  # };
  # systemd.timers.restic-prune = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "Sun 04:00";
  #     Persistent = true;
  #   };
  # };
}
