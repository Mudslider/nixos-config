{ ... }:

{
  # ── Netdata ───────────────────────────────────────────────
  # Echtzeit-System-Monitoring: CPU, RAM, Temperatur, ZFS, SMART, Netzwerk
  # ~150 MB RAM, Hunderte Metriken out-of-the-box

  services.netdata = {
    enable = true;
    config = {
      global = {
        "memory mode" = "dbengine";
        "page cache size" = "64";                  # MB
        "dbengine multihost disk space" = "256";   # MB Retention
        "update every" = "2";                      # Sekunden
      };
      web = {
        "default port" = "19999";
        "bind to" = "127.0.0.1";  # Nur lokal, Zugriff über Caddy
      };
      # ZFS-Monitoring aktivieren
      "plugin:proc" = {
        "/proc/spl/kstat/zfs/arcstats" = "yes";
      };
    };
  };
}
