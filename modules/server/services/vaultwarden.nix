{ config, ... }:
{
  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets."vaultwarden-env".path;
    config = {
      DOMAIN = "https://vaultwarden.home.lan";
      SIGNUPS_ALLOWED = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      WEBSOCKET_ENABLED = true;
    };
    backupDir = "/srv/ssd-buffer/services/vaultwarden/backup";
  };
}
