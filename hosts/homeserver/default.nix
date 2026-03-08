{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  # ── Hostname ──────────────────────────────────────────────
  networking.hostName = "homeserver";

  # ZFS benötigt eine eindeutige hostId
  # Generiere mit: head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
  networking.hostId = "687e79ce"; # TODO: Ersetze mit deiner generierten hostId

  # Sleep verhindern
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # ── Bootloader ────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

    # INSTALLATIONSPHASE: Einfaches Passwort für Konsolen-Login.
    # → In der Härtungsphase (doc 18) durch SOPS-Secret ersetzen.
    initialPassword = "server";

    # SSH-Keys: Deklarativ — überlebt jeden Rebuild!
    # Ersetze mit deinem echten Key: cat ~/.ssh/id_ed25519.pub
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJaOYhzMMUu87VTvyw0ORH5J4LUaRPj3uAQYgAwF7mAs philip@laptop"
    ];

    # Post Quantum sichere verschlüsselung
    services.openssh.settings.KexAlgorithms = [
      "sntrup761x25519-sha512@openssh.com"
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
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

      # INSTALLATIONSPHASE: Passwort-Auth als Rettungsanker aktiviert
      # → In der Härtungsphase (doc 18) auf false setzen
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;

      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11";
}
