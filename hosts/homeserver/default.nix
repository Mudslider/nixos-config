{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # ── Hostname ──────────────────────────────────────────────
  networking.hostName = "homeserver";

  # ZFS benötigt eine eindeutige hostId
  # KRITISCH: Darf NIEMALS geändert werden (sonst schlägt zfs-import-tank fehl!)
  networking.hostId = "687e79ce";

  # Sleep verhindern (Headless-Server)
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # ── Bootloader ────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.zfs.forceImportAll = true;
  boot.zfs.forceImportRoot = lib.mkForce true;

  # ── Benutzer ──────────────────────────────────────────────
  users.users.philip = {
    isNormalUser = true;
    description = "Server Administrator";
    extraGroups = [
      "wheel"       # sudo
      "networkmanager"
      "docker"      # Podman-Kompatibilität
      "video"       # GPU-Zugriff (Jellyfin Transcoding)
      "render"      # GPU-Zugriff
    ];

    hashedPassword = "$2b$05$bHiPVnliRrgU0nwStOVzjumr2fkRQ0.fPkwKx0ESueXnoG6RBQsIu";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaOYhzMMUu87VTvyw0ORH5J4LUaRPj3uAQYgAwF7mAs philip@laptop"
    ];

    shell = pkgs.bash;
  };

  users.groups.philip = {};

  # Root: Nur per SSH-Key
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaOYhzMMUu87VTvyw0ORH5J4LUaRPj3uAQYgAwF7mAs philip@laptop"
  ];

  # Sudo ohne Passwort (praktisch für Wartung)
  security.sudo.extraRules = [{
    users = [ "philip" ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];

  # ── SSH ───────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "prohibit-password";
      X11Forwarding = false;

      # Härtungsphase (doc 18): auf false setzen
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;

      KexAlgorithms = [
        "sntrup761x25519-sha512@openssh.com"
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
    };
  };
  # SSH-Firewall: modules/server/security/firewall.nix (LAN + NetBird)

  system.stateVersion = "24.11";
}
