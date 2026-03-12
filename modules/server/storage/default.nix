{ ... }:
{
  imports = [
    ./ssd-buffer.nix
    ./backup.nix

    # Inaktiv — braucht laufenden ZFS-Pool bzw. Freund-Server
    # ./nightly-sync.nix
    # ./offsite-backup.nix
  ];
}
