{ ... }:

{
  # ── Authentik (SSO / Identity Provider) ───────────────────
  # Open-Source SSO auf Python-Basis (~300-500 MB RAM, leichter als Keycloak).
  # Unterstützt OIDC, SAML, LDAP, Proxy-Auth.
  #
  # Dein Freund nutzt Authentik für die NetBird-Instanz.
  # Diese Authentik-Instanz hier ist DEIN lokaler SSO-Provider
  # für deine Homeserver-Dienste (Nextcloud, Forgejo, Jellyfin, etc.).

  virtualisation.oci-containers.containers = {
    authentik-postgres = {
      image = "docker.io/library/postgres:16-alpine";
      extraOptions = [ "--network=authentik-net" ];
      volumes = [
        "authentik-pgdata:/var/lib/postgresql/data"
      ];
      environment = {
        POSTGRES_PASSWORD = "authentik-db-internal"; # Nur Container-Netz
        POSTGRES_USER = "authentik";
        POSTGRES_DB = "authentik";
      };
      autoStart = true;
    };

    authentik-redis = {
      image = "docker.io/library/redis:7-alpine";
      extraOptions = [
        "--network=authentik-net"
      ];
      autoStart = true;
    };

    authentik-server = {
      image = "ghcr.io/goauthentik/server:latest";
      # TODO: Pinne Version, z.B.: ghcr.io/goauthentik/server:2024.12.3
      ports = [ "9000:9000" ];
      extraOptions = [ "--network=authentik-net" ];
      dependsOn = [ "authentik-postgres" "authentik-redis" ];
      cmd = [ "server" ];
      volumes = [
        "/srv/ssd-buffer/services/authentik/media:/media"
        "/srv/ssd-buffer/services/authentik/templates:/templates"
      ];
      environment = {
        AUTHENTIK_REDIS__HOST = "authentik-redis";
        AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
        AUTHENTIK_POSTGRESQL__USER = "authentik";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
        AUTHENTIK_POSTGRESQL__PASSWORD = "authentik-db-internal";
        # Secret Key: Generiere mit `openssl rand -hex 50`
        # TODO: Ersetze mit echtem Secret oder nutze sops
        AUTHENTIK_SECRET_KEY = "CHANGE-ME-generate-with-openssl-rand-hex-50";
        # Basis-URL (muss zur Caddy-Config passen)
        AUTHENTIK_HOST = "https://auth.home.lan";
        AUTHENTIK_INSECURE = "true"; # Interne TLS-Zertifikate akzeptieren
      };
      autoStart = true;
    };

    authentik-worker = {
      image = "ghcr.io/goauthentik/server:latest";
      extraOptions = [ "--network=authentik-net" ];
      dependsOn = [ "authentik-postgres" "authentik-redis" ];
      cmd = [ "worker" ];
      volumes = [
        "/srv/ssd-buffer/services/authentik/media:/media"
        "/srv/ssd-buffer/services/authentik/templates:/templates"
        "/srv/ssd-buffer/services/authentik/certs:/certs"
      ];
      environment = {
        AUTHENTIK_REDIS__HOST = "authentik-redis";
        AUTHENTIK_POSTGRESQL__HOST = "authentik-postgres";
        AUTHENTIK_POSTGRESQL__USER = "authentik";
        AUTHENTIK_POSTGRESQL__NAME = "authentik";
        AUTHENTIK_POSTGRESQL__PASSWORD = "authentik-db-internal";
        AUTHENTIK_SECRET_KEY = "CHANGE-ME-generate-with-openssl-rand-hex-50";
      };
      autoStart = true;
    };
  };

  # Podman-Netzwerk für Authentik: definiert in podman.nix (zentral)

  # Systemd-Abhängigkeiten
  systemd.services.podman-authentik-postgres.after = [ "podman-network-authentik.service" ];
  systemd.services.podman-authentik-redis.after = [ "podman-network-authentik.service" ];
  systemd.services.podman-authentik-server.after = [ "podman-network-authentik.service" ];
  systemd.services.podman-authentik-worker.after = [ "podman-network-authentik.service" ];

  # ── Verzeichnisse ─────────────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /srv/ssd-buffer/services/authentik          0750 root root -"
    "d /srv/ssd-buffer/services/authentik/media     0750 root root -"
    "d /srv/ssd-buffer/services/authentik/templates  0750 root root -"
    "d /srv/ssd-buffer/services/authentik/certs     0750 root root -"
  ];

  # ────────────────────────────────────────────────────────────
  # OIDC-Integration für Dienste (nach Authentik-Setup konfigurieren):
  #
  # Nextcloud:  App "Social Login" oder "OpenID Connect"
  #             → Provider in Authentik anlegen → Client-ID/Secret eintragen
  # Forgejo:    settings.oauth2 in forgejo.nix
  # Jellyfin:   Plugin "SSO Authentication"
  # Immich:     Einstellungen → OAuth → Authentik als Provider
  # PaperlessNGX: Unterstützt Remote-User-Header via Authentik Proxy
  #
  # Anleitung: https://docs.goauthentik.io/integrations/
  # ────────────────────────────────────────────────────────────
}
