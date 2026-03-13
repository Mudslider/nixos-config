{ pkgs, ... }:

{
  # ── Backrest — Web UI für Restic-Backups ──────────────────
  # Zeigt Snapshots, Größen, Backup-Historie des Restic REST-Servers.
  # Erreichbar unter https://backrest.home.lan

  users.users.backrest = {
    isSystemUser = true;
    group = "backrest";
    # Zugriff auf Backup-Daten (Restic REST-Server Verzeichnis)
    extraGroups = [ "restic" ];
  };
  users.groups.backrest = {};

  systemd.services.backrest = {
    description = "Backrest Web UI for Restic";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "restic-rest-server.service" ];
    environment = {
      BACKREST_PORT = "9898";
      BACKREST_DATA = "/srv/ssd-buffer/services/backrest";
      XDG_CONFIG_HOME = "/srv/ssd-buffer/services/backrest";
      XDG_CACHE_HOME = "/srv/ssd-buffer/services/backrest/cache";
    };
    serviceConfig = {
      ExecStart = "${pkgs.backrest}/bin/backrest";
      User = "backrest";
      Group = "backrest";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
