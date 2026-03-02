# ── ThinkPad P15 ────────────────────────────────────────────
#
# TODO: Migriere die bestehende Config von ~/nixos-config (altes Repo)
#       hierher. Benötigte Dateien:
#       - hardware-configuration.nix (von nixos-generate-config)
#       - NVIDIA-Config (PRIME Offload)
#       - KDE Plasma 6
#       - Desktop-Pakete (Firefox, Thunderbird, etc.)
#
# Rebuild: sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-p15
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # ./hardware-configuration.nix  # TODO: Kopiere von altem Repo
  ];

  networking.hostName = "playground";

  # ── Bootloader ────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Benutzer ──────────────────────────────────────────────
  users.users.polly = {
    isNormalUser = true;
    description = "Polly";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
    shell = pkgs.bash;
  };

  # ── Desktop (TODO: in modules/desktop/ auslagern) ─────────
  # services.desktopManager.plasma6.enable = true;
  # services.displayManager.sddm.enable = true;

  system.stateVersion = "24.11";
}
