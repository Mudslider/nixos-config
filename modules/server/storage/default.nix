{ ... }:
{
  imports = [
    ./ssd-buffer.nix
    ./backup.nix

    ./nightly-sync.nix

    # ./offsite-backup.nix  # deaktiviert — Missverständnis mit Bruder, später neu einrichten
  ];
}
