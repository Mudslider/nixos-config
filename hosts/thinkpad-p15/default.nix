# ── ThinkPad P15 (maschinenspezifisch) ──────────────────────
# Desktop-Umgebung, Audio, Pakete etc. kommen aus modules/desktop/
{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./backup.nix
  ];

  # ── Boot ──────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Netzwerk ──────────────────────────────────────────────
  networking.hostName = "playground";

  networking.networkmanager = {
    enable = true;
    dns = "systemd-resolved";  # NetworkManager nutzt systemd-resolved
  };

  # Split-DNS: home.lan über Homeserver (NetBird), Rest über DHCP-DNS
  # DNS wird per-Interface auf nb-wt0 gesetzt, NICHT global in resolved.conf,
  # damit bei NetBird-Ausfall normales DNS weiter funktioniert.
  services.resolved.enable = true;

  systemd.services.netbird-dns = {
    description = "Split-DNS für home.lan via NetBird";
    wantedBy = [ "multi-user.target" ];
    after = [ "netbird.service" ];
    wants = [ "netbird.service" ];
    path = [ pkgs.systemd pkgs.iproute2 ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Warten bis nb-wt0 existiert, dann DNS nur für dieses Interface setzen
      # NetBird-Interface heißt wt0 auf dem Laptop (nb-wt0 auf dem Server)
      ExecStart = pkgs.writeShellScript "netbird-dns" ''
        for i in $(seq 1 30); do
          if ip link show wt0 &>/dev/null; then
            resolvectl dns wt0 100.95.103.67
            resolvectl domain wt0 ~home.lan
            echo "Split-DNS für home.lan auf wt0 konfiguriert"
            exit 0
          fi
          sleep 1
        done
        echo "wt0 nicht gefunden nach 30s" >&2
        exit 1
      '';
    };
  };

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

  # ── Container (Podman + NVIDIA GPU) ─────────────────────
  virtualisation.podman.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  # ── Dienste ───────────────────────────────────────────────
  services.openssh.enable = true;
  # services.netbird.enable — kaputt in nixpkgs 26.05.20260312 (netbird 0.65.3 wrapper bug)
  # Workaround: Daemon direkt als systemd-Service starten
  systemd.services.netbird = {
    description = "NetBird VPN Daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.netbird}/bin/netbird service run";
      Restart = "on-failure";
      RuntimeDirectory = "netbird";
    };
  };

  # ── Benutzer ──────────────────────────────────────────────
  users.users.polly = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    hashedPassword = "$6$3VeeiTjP3MqYWYcE$g4Oq60CkvcjMaqO77R7/o.w4YVAJfiiSYYxQCHYUz0ERbcdpPRzdziO7sOqu9.kj1dqe0GAOvuKonCYqPapmk.";
  };

  # ── Homeserver-Vertrauen ──────────────────────────────────
  # Caddy Root CA für lokale TLS-Zertifikate (vaultwarden.home.lan etc.)
  security.pki.certificateFiles = [
    ./caddy-root-ca.crt
  ];

  system.stateVersion = "25.11";
}
