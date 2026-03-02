{ config, ... }:

{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://vaultwarden.home.lan";
      SIGNUPS_ALLOWED = false;  # WICHTIG: Registrierung deaktivieren!
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      DATABASE_URL = "sqlite:///srv/ssd-buffer/services/vaultwarden/db.sqlite3";
      # Websocket für Push-Benachrichtigungen
      WEBSOCKET_ENABLED = true;
      # Admin-Panel (über separaten Token gesichert)
      ADMIN_TOKEN = ""; # TODO: Generiere mit: openssl rand -base64 48
    };
    backupDir = "/srv/ssd-buffer/services/vaultwarden/backup";
  };
}
