{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # CLI-Basics
    git
    nano
    wget
    curl
    jq

    # System
    htop
    btop
    tree
    ncdu
    duf
    lsof
    pciutils
    usbutils
    nodejs

    # Claude
    claude-code
    claude-monitor

    # Dateien
    rsync
    unzip
    p7zip

    # NixOS
    nix-tree
    nix-diff
    nvd

    # Secrets & VPN
    sops
    age
    netbird
  ];
}
