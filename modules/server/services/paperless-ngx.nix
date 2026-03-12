{ ... }:

{
  # ── PaperlessNGX ──────────────────────────────────────────
  # Dokumentenmanagement mit OCR (Tesseract) + ML-Klassifizierung.
  # ML lernt automatisch aus manuellen Tags/Korrespondenten → wird besser mit der Zeit.
  #
  # Consume-Ordner: /srv/ssd-buffer/documents/ → Dateien hier ablegen = automatischer Import
  # Erster Login: philip / changeme → Passwort sofort ändern!

  virtualisation.oci-containers.containers = {
    paperless-redis = {
      image = "docker.io/library/redis:7-alpine";
      extraOptions = [ "--network=paperless-net" ];
      autoStart = true;
    };

    paperless = {
      image = "ghcr.io/paperless-ngx/paperless-ngx:2.14.7";
      ports = [ "127.0.0.1:8000:8000" ];
      extraOptions = [ "--network=paperless-net" ];
      dependsOn = [ "paperless-redis" ];
      volumes = [
        "/srv/ssd-buffer/services/paperless/data:/usr/src/paperless/data"
        "/srv/ssd-buffer/services/paperless/media:/usr/src/paperless/media"
        "/srv/ssd-buffer/documents:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_REDIS            = "redis://paperless-redis:6379";
        PAPERLESS_TIME_ZONE        = "Europe/Berlin";
        PAPERLESS_URL              = "https://paperless.home.lan";
        PAPERLESS_ADMIN_USER       = "philip";
        PAPERLESS_ADMIN_PASSWORD   = "changeme";   # Sofort nach Erstlogin ändern!

        # ── OCR ───────────────────────────────────────────────
        PAPERLESS_OCR_LANGUAGE     = "deu+eng";    # Deutsch + Englisch
        PAPERLESS_OCR_MODE         = "skip_noarchive"; # Nur scannen wenn nötig
        PAPERLESS_OCR_SKIP_ARCHIVE_FILE = "with_text"; # PDFs mit Text überspringen

        # ── ML-Klassifizierung ─────────────────────────────────
        # Lernt automatisch Korrespondenten, Tags, Dokumenttypen aus deinen Entscheidungen
        PAPERLESS_TASK_WORKERS     = "2";          # N100: max 2 Worker

        # ── Dateiorganisation ──────────────────────────────────
        PAPERLESS_FILENAME_FORMAT  = "{created_year}/{correspondent}/{title}";

        # ── Consume-Ordner ─────────────────────────────────────
        PAPERLESS_CONSUMER_RECURSIVE        = "true"; # Unterordner scannen
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS  = "true"; # Unterordnernamen → Tags
      };
      autoStart = true;
    };
  };

  systemd.services.podman-paperless-redis.after = [ "podman-network-paperless.service" ];
  systemd.services.podman-paperless.after       = [ "podman-network-paperless.service" ];
}
