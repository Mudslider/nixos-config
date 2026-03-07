# ── ThinkPad P15 ────────────────────────────────────────────
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Netzwerk ──────────────────────────────────────────────
  networking.hostName = "playground";
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
    192.168.1.10  vaultwarden.home.lan
  '';

  # ── Locale & Zeit ────────────────────────────────────────
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "de_DE.UTF-8";

  # ── Desktop: KDE Plasma 6 ────────────────────────────────
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ── NVIDIA (PRIME Offload) ───────────────────────────────
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ── Audio ─────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ── Dienste ───────────────────────────────────────────────
  services.openssh.enable = true;
  services.printing.enable = true;
  hardware.bluetooth.enable = true;

  # ── Benutzer ──────────────────────────────────────────────
  users.users.polly = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "REDACTED";
  };

  # ── Pakete ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    firefox
    thunderbird
    obsidian
    git
    nano
    wget
    curl
  ];

  # ── Nix-Einstellungen ────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.11";
}
