{ ... }:
{
  imports = [
    ./ssd-buffer.nix
    ./backup.nix
    # ./nightly-sync.nix       # TEMPORÄR — braucht /tank, erst nach Anleitung 01
    # ./offsite-backup.nix     # TEMPORÄR — braucht sops + Freund-Server
  ];
}
