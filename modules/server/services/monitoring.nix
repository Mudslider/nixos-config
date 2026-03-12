{ config, ... }:

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
}
