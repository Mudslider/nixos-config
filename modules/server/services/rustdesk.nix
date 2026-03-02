{ ... }:

{
  # ── RustDesk ──────────────────────────────────────────────
  # Open-Source Remote-Desktop (Alternative zu AnyDesk)
  # Eigener Relay-Server für volle Kontrolle über den Traffic

  virtualisation.oci-containers.containers = {
    rustdesk-hbbs = {
      image = "rustdesk/rustdesk-server:latest";
      ports = [
        "21115:21115"
        "21116:21116"
        "21116:21116/udp"
        "21118:21118"
      ];
      cmd = [ "hbbs" ];
      volumes = [
        "/srv/ssd-buffer/services/rustdesk:/root"
      ];
      autoStart = true;
    };

    rustdesk-hbbr = {
      image = "rustdesk/rustdesk-server:latest";
      ports = [
        "21117:21117"
      ];
      cmd = [ "hbbr" ];
      volumes = [
        "/srv/ssd-buffer/services/rustdesk:/root"
      ];
      autoStart = true;
    };
  };

  # Ports für RustDesk öffnen (nur im Heimnetz und über NetBird)
  networking.firewall.allowedTCPPorts = [ 21115 21116 21117 21118 ];
  networking.firewall.allowedUDPPorts = [ 21116 ];
}
