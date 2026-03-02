# ── Firewall (nur Heimnetz, kein VPN vorerst) ──────────────
{ ... }:
{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      443        # Caddy HTTPS (nur LAN-erreichbar)
    ];

    allowedUDPPorts = [
      # 51820    # NetBird/WireGuard — erst nach VPN-Setup aktivieren
    ];

    # NetBird-Interface erst aktivieren, wenn VPN eingerichtet ist:
    # trustedInterfaces = [ "wt0" ];

    # SSH nur aus dem Heimnetz
    extraCommands = ''
      iptables -I INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
      iptables -A INPUT -p tcp --dport 22 -j DROP
    '';
    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 22 -j DROP || true
    '';
  };
}
