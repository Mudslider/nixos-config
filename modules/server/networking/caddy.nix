{ ... }:

{
  # ── Caddy Reverse Proxy ───────────────────────────────────
  # KEIN öffentliches HTTPS (keine Domain, kein public IPv4).
  # Stattdessen: Caddy's interne CA für lokale TLS-Zertifikate.
  #
  # Zugriff:
  #   Lokal:  https://nextcloud.home.lan (pfSense DNS → 192.168.1.10)
  #   Remote: Über NetBird-Tunnel (gleiche Hostnamen, DNS via NetBird)
  #
  # Damit Browser keine Zertifikatswarnungen zeigen, installiere
  # Caddy's Root-CA auf allen Clients:
  #   /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt
  #   → Kopiere auf Clients und importiere als vertrauenswürdige CA.

  services.caddy = {
    enable = true;

    # Globale Einstellungen
    globalConfig = ''
      # Kein HTTP-Port (kein public IPv4, keine Redirects nötig)
      http_port 0
    '';

    virtualHosts = {
      # ── Nextcloud ─────────────────────────────────────
      "nextcloud.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8080
          header {
            Strict-Transport-Security "max-age=31536000; includeSubDomains"
          }
        '';
      };

      # ── Immich ────────────────────────────────────────
      "immich.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:2283
          request_body {
            max_size 50GB
          }
        '';
      };

      # ── Jellyfin ──────────────────────────────────────
      "jellyfin.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8096
        '';
      };

      # ── PaperlessNGX ──────────────────────────────────
      "paperless.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8000

          # ── Authentik Proxy-Auth (einkommentieren nach Authentik-Setup) ──
          # Ersetzt den einfachen reverse_proxy oben. Entferne dann die
          # Zeile "reverse_proxy localhost:8000" oberhalb und nutze stattdessen:
          #
          # forward_auth localhost:9000 {
          #   uri /outpost.goauthentik.io/auth/caddy
          #   copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email
          #   trusted_proxies private_ranges
          # }
          # reverse_proxy localhost:8000
        '';
      };

      # ── Forgejo ───────────────────────────────────────
      "forgejo.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:3000
        '';
      };

      # ── Vaultwarden ───────────────────────────────────
      "vaultwarden.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8222
        '';
      };

      # ── Audiobookshelf ────────────────────────────────
      "audiobookshelf.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:13378
        '';
      };

      # ── Navidrome ─────────────────────────────────────
      "navidrome.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:4533
        '';
      };

      # ── Home Assistant ────────────────────────────────
      "hass.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:8123
        '';
      };

      # ── Uptime Kuma ───────────────────────────────────
      "status.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:3001
        '';
      };

      # ── Netdata ───────────────────────────────────────
      "netdata.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:19999

          # ── Authentik Proxy-Auth (einkommentieren nach Authentik-Setup) ──
          # forward_auth localhost:9000 {
          #   uri /outpost.goauthentik.io/auth/caddy
          #   copy_headers X-Authentik-Username X-Authentik-Groups X-Authentik-Email
          #   trusted_proxies private_ranges
          # }
          # reverse_proxy localhost:19999
        '';
      };

      # ── Authentik ─────────────────────────────────────
      "auth.home.lan" = {
        extraConfig = ''
          tls internal
          reverse_proxy localhost:9000
        '';
      };
    };
  };
}
