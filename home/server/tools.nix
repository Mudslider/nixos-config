{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Netzwerk
    curl
    wget
    dig
    nmap
    iftop
    tcpdump

    # System
    htop
    btop
    tree
    ncdu         # Speicherplatz-Analyse
    duf          # Disk Usage (hübscher als df)
    lsof
    pciutils
    usbutils

    # Dateien
    rsync
    unzip
    p7zip
    jq           # JSON-Verarbeitung
    restic       # Backup (Offsite + lokaler Prune)

    # NixOS
    nix-tree     # Dependency-Visualisierung
    nix-diff     # Generationen vergleichen
    nvd          # NixOS Version Diff (zeigt Änderungen bei rebuild)

    # Monitoring
    powertop
    intel-gpu-tools  # intel_gpu_top für Transcoding-Monitoring

    # Secrets
    sops
    age
  ];
}
