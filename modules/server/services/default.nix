{ ... }:
{
  imports = [
    ./podman.nix
    # TEMPORÄR DEAKTIVIERT — einzeln aktivieren nach Anleitungen 04-15
    # ./nextcloud.nix
    # ./paperless-ngx.nix
    # ./immich.nix
    # ./jellyfin.nix
    # ./audiobookshelf.nix
    # ./navidrome.nix
    # ./vaultwarden.nix
    # ./forgejo.nix
    # ./home-assistant.nix
    # ./syncthing.nix
    # ./authentik.nix
    # ./uptime-kuma.nix
    # ./netdata.nix
    # ./rustdesk.nix
  ];
}
