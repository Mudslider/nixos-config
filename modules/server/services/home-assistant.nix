{ ... }:

{
  services.home-assistant = {
    enable = true;
    configDir = "/srv/ssd-buffer/services/hass";

    config = {
      homeassistant = {
        name = "Home";
        time_zone = "Europe/Berlin";
        unit_system = "metric";
        temperature_unit = "C";
        country = "DE";
        language = "de";
      };
      http = {
        server_port = 8123;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
      };
      # Grundlegende Integrationen
      default_config = {};
    };

    # Zusätzliche Python-Pakete für Integrationen
    extraPackages = python3Packages: with python3Packages; [
      # Hier bei Bedarf Pakete ergänzen, z.B.:
      # psycopg2
    ];

    # Zusätzliche Komponenten
    extraComponents = [
      "met"          # Wetter
      "radio_browser" # Internet Radio
      "backup"       # Backups
    ];
  };
}
