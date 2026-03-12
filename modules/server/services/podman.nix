{ pkgs, ... }:

{
  # ── Podman als Container-Runtime ──────────────────────────
  # Rootless, daemonless, besser in NixOS integriert als Docker

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;      # docker CLI Kompatibilität
    defaultNetwork.settings = {
      dns_enabled = true;     # Container-DNS für Name-Resolution
    };
  };

  # OCI-Container Backend auf Podman setzen
  virtualisation.oci-containers.backend = "podman";

  # ── Podman-Netzwerke für Dienste-Gruppen ──────────────────
  # Container die miteinander sprechen müssen, kommen ins gleiche Netzwerk.
  # Netzwerke erst einkommentieren wenn der zugehörige Dienst aktiviert wird!

  # systemd.services.podman-network-immich = {
  #   description = "Create Podman network for Immich";
  #   after = [ "podman.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.podman}/bin/podman network create immich-net --ignore";
  #   };
  # };

  # systemd.services.podman-network-paperless = {
  #   description = "Create Podman network for PaperlessNGX";
  #   after = [ "podman.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.podman}/bin/podman network create paperless-net --ignore";
  #   };
  # };

  # systemd.services.podman-network-authentik = {
  #   description = "Create Podman network for Authentik";
  #   after = [ "podman.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.podman}/bin/podman network create authentik-net --ignore";
  #   };
  # };

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
