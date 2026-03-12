{ ... }:
{
  imports = [
    ./podman.nix
    ./vaultwarden.nix

    # Inaktiv — einzeln aktivieren nach den jeweiligen Anleitungen (docs/)
    # ./nextcloud.nix
    # ./paperless-ngx.nix
    # ./immich.nix
    # ./jellyfin.nix
    # ./audiobookshelf.nix
    # ./navidrome.nix
    # ./forgejo.nix
    # ./home-assistant.nix
    # ./syncthing.nix
    # ./authentik.nix
    ./uptime-kuma.nix
    ./netdata.nix
    # ./rustdesk.nix
  ];
}
