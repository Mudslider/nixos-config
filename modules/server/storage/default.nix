{ ... }:
{
  imports = [
    ./ssd-buffer.nix
    ./backup.nix

    ./nightly-sync.nix

    # Inaktiv — braucht konfigurierten Freund-Server
    # ./offsite-backup.nix
  ];
}
