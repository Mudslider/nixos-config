{ config, pkgs, ... }:

{
  # ── Prometheus + node_exporter ────────────────────────────
  services.prometheus = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9090;
    retentionTime = "30d";

    exporters.node = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = 9100;
      enabledCollectors = [ "systemd" "zfs" ];
    };

    scrapeConfigs = [
      {
        job_name = "homeserver";
        static_configs = [{ targets = [ "127.0.0.1:9100" ]; }];
      }
    ];
  };

  # ── Grafana ───────────────────────────────────────────────
  services.grafana = {
    enable = true;
    dataDir = "/srv/ssd-buffer/services/grafana";

    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3100;
        domain = "grafana.home.lan";
        root_url = "https://grafana.home.lan";
      };
      security.secret_key = "$__file{/srv/ssd-buffer/services/grafana/secret_key}";
      analytics.reporting_enabled = false;
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        url = "http://127.0.0.1:9090";
        isDefault = true;
      }];
    };
  };

  # Secret-Key automatisch generieren falls nicht vorhanden
  systemd.services.grafana-secret-key = {
    description = "Generate Grafana secret key if missing";
    before = [ "grafana.service" ];
    wantedBy = [ "grafana.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "grafana-secret-key" ''
        KEY_FILE="/srv/ssd-buffer/services/grafana/secret_key"
        if [ ! -f "$KEY_FILE" ]; then
          ${pkgs.openssl}/bin/openssl rand -base64 32 > "$KEY_FILE"
          chown grafana:grafana "$KEY_FILE"
          chmod 600 "$KEY_FILE"
          echo "Grafana secret_key generiert"
        fi
      '';
    };
  };
}
