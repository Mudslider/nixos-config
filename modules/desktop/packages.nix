# ── Desktop-Pakete (nur GUI-Apps) ───────────────────────────
# CLI-Tools und Secrets kommen über Home-Manager (home/laptop/tools.nix)
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    firefox
    thunderbird
    signal-desktop
    obsidian
  ];
}
