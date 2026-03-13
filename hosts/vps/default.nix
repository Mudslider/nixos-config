# ── Hetzner VPS (philipjonasch.de Eingangsknoten) ───────────
# Öffentlicher Reverse Proxy: Let's Encrypt + NetBird-Tunnel → Homeserver
{ pkgs, ... }:
{
  imports = [
    ./disk.nix
    ./caddy.nix
    ./netbird.nix
    ./firewall.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  # disko konfiguriert GRUB via EF02-Partition automatisch
  boot.loader.grub.enable = true;

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
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;  # Nur Key-Auth
      PermitRootLogin = "prohibit-password";
    };
  };

  # ── SOPS ──────────────────────────────────────────────────
  # age-Key des VPS nach Erstellung hinzufügen:
  #   ssh-keyscan VPS_IP | ssh-to-age  → in secrets/secrets.yaml eintragen
  #   sops updatekeys secrets/secrets.yaml
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  environment.systemPackages = with pkgs; [ htop curl ];

  system.stateVersion = "25.11";
}
