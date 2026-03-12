{ ... }:

{
  virtualisation.oci-containers.containers.uptime-kuma = {
    image = "louislam/uptime-kuma:2.2.1";
    ports = [ "3001:3001" ];
    volumes = [
      "/srv/ssd-buffer/services/uptime-kuma:/app/data"
    ];
    environment = {
      TZ = "Europe/Berlin";
    };
    autoStart = true;
  };
}
