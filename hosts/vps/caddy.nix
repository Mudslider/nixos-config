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

    # Security-Headers als Snippet — wird in jedem Host importiert
    extraConfig = ''
      (security-headers) {
        header {
          Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
          X-Content-Type-Options "nosniff"
          X-Frame-Options "DENY"
          Referrer-Policy "strict-origin-when-cross-origin"
          -Server
        }
      }
    '';

    virtualHosts = {
      "nextcloud.philipjonasch.de" = {
        extraConfig = ''
          import security-headers
          reverse_proxy 100.95.103.67:80
        '';
      };

      "immich.philipjonasch.de" = {
        extraConfig = ''
          import security-headers
          reverse_proxy 100.95.103.67:80
          request_body {
            max_size 50GB
          }
        '';
      };

      "vaultwarden.philipjonasch.de" = {
        extraConfig = ''
          import security-headers

          # Admin-Panel nur über vaultwarden.home.lan erreichbar, nicht öffentlich
          @admin path /admin*
          respond @admin 403

          reverse_proxy 100.95.103.67:80
        '';
      };

      "paperless.philipjonasch.de" = {
        extraConfig = ''
          import security-headers
          reverse_proxy 100.95.103.67:80
        '';
      };
    };
  };
}
