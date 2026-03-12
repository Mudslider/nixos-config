{ ... }:

{
  # ── Caddy Reverse Proxy ───────────────────────────────────
  # Interne CA für lokale TLS-Zertifikate (kein öffentliches HTTPS).
  # Caddy's Root-CA muss auf allen Clients importiert werden:
  #   /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt

  services.caddy = {
    enable = true;

    globalConfig = ''
      # Kein HTTP-Port (kein public IPv4)
      http_port 0
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

      "immich.home.lan" = {
        extraConfig = ''
          tls internal
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

      "ntfy.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8084
        '';
      };

      "netdata.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:19999
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
