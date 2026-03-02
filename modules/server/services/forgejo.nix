{ config, ... }:

{
  services.forgejo = {
    enable = true;
    stateDir = "/srv/ssd-buffer/services/forgejo";
    database = {
      type = "sqlite3";
    };
    settings = {
      server = {
        DOMAIN = "forgejo.home.lan";
        ROOT_URL = "https://forgejo.home.lan/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        # SSH über den Server-Port (wenn Git über SSH gewünscht)
        SSH_PORT = 2222;
        START_SSH_SERVER = true;
      };
      service = {
        DISABLE_REGISTRATION = true; # Keine öffentliche Registrierung
        REQUIRE_SIGNIN_VIEW = true;  # Repos nur nach Login sichtbar
      };
      session = {
        COOKIE_SECURE = true;
      };
      repository = {
        DEFAULT_PRIVATE = "private";
      };

      # ── Authentik SSO (einkommentieren nach Authentik-Setup) ──
      # Siehe Anleitung 12-authentik-sso.md
      # oauth2 = {
      #   ENABLE = true;
      # };
    };
  };

  # SSH-Port für Git
  networking.firewall.allowedTCPPorts = [ 2222 ];
}
