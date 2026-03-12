# ── ThinkPad P15 (maschinenspezifisch) ──────────────────────
# Desktop-Umgebung, Audio, Pakete etc. kommen aus modules/desktop/
{ pkgs, ... }:
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

  # ── NVIDIA (PRIME Offload — PCI-Adressen maschinenspezifisch) ──
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

  # ── Dienste ───────────────────────────────────────────────
  services.openssh.enable = true;

  # ── Benutzer ──────────────────────────────────────────────
  users.users.polly = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
  };

  # ── Homeserver-Vertrauen ──────────────────────────────────
  # Caddy Root CA für lokale TLS-Zertifikate (vaultwarden.home.lan etc.)
  security.pki.certificateFiles = [
    ./caddy-root-ca.crt
  ];

  system.stateVersion = "25.11";
}
