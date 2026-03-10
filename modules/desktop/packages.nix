# ── Desktop-Pakete ──────────────────────────────────────────
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Browser & Kommunikation
    firefox
    thunderbird
    signal-desktop

    # Produktivität
    obsidian

    # CLI-Tools
    git
    nano
    wget
    curl

    # Secrets & VPN
    sops
    age
    netbird
  ];
}
