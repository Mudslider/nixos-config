{ config, pkgs, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud30; # TODO: Prüfe aktuelle Version bei nixpkgs
    hostName = "nextcloud.home.lan";
    https = true;
    configureRedis = true;
    database.createLocally = true;

    config = {
      dbtype = "pgsql";
      adminuser = "philip";
      adminpassFile = config.sops.secrets."nextcloud-admin-pass".path;
    };

    settings = {
      default_phone_region = "DE";
      maintenance_window_start = 4;
      overwriteprotocol = "https";
      trusted_domains = [
        "nextcloud.home.lan"
        "192.168.1.10"
      ];
      trusted_proxies = [
        "127.0.0.1"
        "::1"
      ];

      # CalDAV/CardDAV: Automatisch durch Nextcloud bereitgestellt
      # Thunderbird: https://nextcloud.home.lan/remote.php/dav
      # DAVx5 (Android): gleiche URL
    };

    # PHP-Limits für große Uploads
    phpOptions = {
      "upload_max_filesize" = "16G";
      "post_max_size" = "16G";
      "memory_limit" = "512M";
      "max_execution_time" = "3600";
    };

    # Automatische App-Updates
    autoUpdateApps.enable = true;
    autoUpdateApps.startAt = "04:00:00";
  };

  # PostgreSQL für Nextcloud (wird automatisch erstellt)
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
  };

  # ── Nginx als interner Upstream für Caddy ─────────────────
  # Das NixOS-Nextcloud-Modul erzwingt nginx. Wir lassen nginx
  # NUR intern auf Port 8080 lauschen. Caddy proxied dorthin.
  #
  # WICHTIG: nginx darf NICHT auf 80/443 lauschen (Caddy braucht 443).
  services.nginx = {
    enable = true;

    # Standard-Ports ändern, damit nginx NICHT auf 80 lauscht
    defaultHTTPListenPort = 8080;
    defaultSSLListenPort = 8443; # Wird nicht genutzt, aber sicher ist sicher

    virtualHosts."nextcloud.home.lan" = {
      listen = [{ addr = "127.0.0.1"; port = 8080; }];
    };
  };
}
