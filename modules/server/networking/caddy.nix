{ ... }:

{
  # ── Caddy Reverse Proxy ───────────────────────────────────
  # Interne CA für lokale TLS-Zertifikate (kein öffentliches HTTPS).
  # Caddy's Root-CA muss auf allen Clients importiert werden:
  #   /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt

  services.caddy = {
    enable = true;

    globalConfig = ''
      # HTTP nur für NetBird-Clients (WireGuard-Tunnel = verschlüsselt)
      http_port 80
    '';

    virtualHosts = {
      # ── Vaultwarden (AKTIV) ───────────────────────────
      "vaultwarden.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8222
        '';
      };

      # ────────────────────────────────────────────────────
      # Inaktive Dienste — einkommentieren bei Aktivierung
      # ────────────────────────────────────────────────────

      # "nextcloud.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:8080
      #     header {
      #       Strict-Transport-Security "max-age=31536000; includeSubDomains"
      #     }
      #   '';
      # };

      # HTTPS für LAN-Clients
      "immich.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:2283
          request_body {
            max_size 50GB
          }
        '';
      };

      # HTTP für NetBird-Clients (Phones) — WireGuard-Tunnel übernimmt Verschlüsselung
      "http://immich.home.lan" = {
        extraConfig = ''
          reverse_proxy localhost:2283
          request_body {
            max_size 50GB
          }
        '';
      };

      # "jellyfin.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:8096
      #   '';
      # };

      # "paperless.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:8000
      #   '';
      # };

      # "forgejo.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:3000
      #   '';
      # };

      # "audiobookshelf.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:13378
      #   '';
      # };

      # "navidrome.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:4533
      #   '';
      # };

      # "hass.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:8123
      #   '';
      # };

      "status.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:3001
        '';
      };

      "grafana.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:3100
        '';
      };

      # HTTPS für LAN-Clients
      "ntfy.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8084
        '';
      };

      # HTTP für NetBird-Clients (Phones)
      "http://ntfy.home.lan" = {
        extraConfig = ''
          reverse_proxy localhost:8084
        '';
      };

      # "auth.home.lan" = {
      #   extraConfig = ''
      #     tls internal
      #     reverse_proxy localhost:9000
      #   '';
      # };
    };
  };
}
