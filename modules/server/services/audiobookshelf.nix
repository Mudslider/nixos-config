{ ... }:

{
  virtualisation.oci-containers.containers.audiobookshelf = {
    image = "ghcr.io/advplyr/audiobookshelf:latest";
    ports = [ "13378:80" ];
    volumes = [
      "/tank/media/audiobooks:/audiobooks"
      "/tank/media/podcasts:/podcasts"
      "/srv/ssd-buffer/services/audiobookshelf/config:/config"
      "/srv/ssd-buffer/services/audiobookshelf/metadata:/metadata"
    ];
    environment = {
      TZ = "Europe/Berlin";
    };
    autoStart = true;
  };
}
