{ ... }:

{
  # ── Caddy Public Reverse Proxy ─────────────────────────────
  # TLS-Terminierung mit Let's Encrypt für philipjonasch.de.
  # Traffic wird via NetBird-Tunnel (WireGuard) zum Homeserver weitergeleitet.
  # Homeserver-Caddy routet intern auf den jeweiligen Dienst.
  #
  # Homeserver NetBird-IP: 100.95.103.67

  services.caddy = {
    enable = true;

    globalConfig = ''
      email p.jonasch@posteo.de
    '';

    virtualHosts = {
      "nextcloud.philipjonasch.de" = {
        extraConfig = ''
          reverse_proxy 100.95.103.67:80
        '';
      };

      "immich.philipjonasch.de" = {
        extraConfig = ''
          reverse_proxy 100.95.103.67:80
          request_body {
            max_size 50GB
          }
        '';
      };

      "vaultwarden.philipjonasch.de" = {
        extraConfig = ''
          # Admin-Panel nur über vaultwarden.home.lan erreichbar, nicht öffentlich
          @admin path /admin*
          respond @admin 403

          reverse_proxy 100.95.103.67:80
        '';
      };

      "paperless.philipjonasch.de" = {
        extraConfig = ''
          reverse_proxy 100.95.103.67:80
        '';
      };
    };
  };
}
