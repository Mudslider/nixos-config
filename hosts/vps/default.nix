# ── Hetzner VPS (philipjonasch.de Eingangsknoten) ───────────
# Öffentlicher Reverse Proxy: Let's Encrypt + NetBird-Tunnel → Homeserver
{ pkgs, ... }:
{
  imports = [
    ./disk.nix
    ./caddy.nix
    ./netbird.nix
    ./firewall.nix
    ./fail2ban.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  # MBR-Layout: GRUB direkt auf /dev/sda, kein EFI
  # disko konfiguriert GRUB automatisch via EF02-Partition
  boot.loader.grub.enable = true;

  # Kernel-Module für Hetzner KVM
  boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

  # ── Netzwerk ──────────────────────────────────────────────
  networking.hostName = "vps";
  networking.useDHCP = true;

  # ── Benutzer ──────────────────────────────────────────────
  users.users.philip = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # SSH-Key eintragen nach VPS-Erstellung:
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaOYhzMMUu87VTvyw0ORH5J4LUaRPj3uAQYgAwF7mAs philip@laptop"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaOYhzMMUu87VTvyw0ORH5J4LUaRPj3uAQYgAwF7mAs philip@laptop"
  ];

  # ── SSH ───────────────────────────────────────────────────
  # Port 2222 statt 22: eliminiert 99% der automatisierten Scans
  services.openssh = {
    enable = true;
    ports = [ 2222 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";  # Nur Key-Auth, nötig für nixos-rebuild --target-host
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };

  # ── SOPS ──────────────────────────────────────────────────
  # age-Key des VPS nach Erstellung hinzufügen:
  #   ssh-keyscan VPS_IP | ssh-to-age  → in secrets/secrets.yaml eintragen
  #   sops updatekeys secrets/secrets.yaml
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # ── Automatische Updates ──────────────────────────────────
  # VPS zieht täglich das Flake von GitHub und rebuildet sich selbst.
  # So bekommt er Security-Patches ohne manuelles nrs.
  system.autoUpgrade = {
    enable = true;
    flake = "github:Mudslider/nixos-config#vps";
    dates = "04:30";            # Nachts, nach dem Homeserver-Sync
    randomizedDelaySec = "15m";
    allowReboot = false;        # Kein automatischer Reboot — nur config-switch
  };

  environment.systemPackages = with pkgs; [ htop curl ];

  system.stateVersion = "25.11";
}
