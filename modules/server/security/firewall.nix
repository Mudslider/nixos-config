# ── Firewall (Heimnetz + NetBird VPN) ──────────────────────
{ ... }:
{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      443        # Caddy HTTPS (nur LAN-erreichbar)
      8100       # Restic REST-Server (Backup vom Arbeitsrechner)
    ];

    allowedUDPPorts = [
      # 51820    # NetBird/WireGuard — wird über openFirewall in netbird.nix geöffnet
    ];

    # SSH nur aus dem Heimnetz und über NetBird
    extraCommands = ''
      iptables -I INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT
      iptables -I INPUT -p tcp --dport 22 -s 192.168.178.0/24 -j ACCEPT
      iptables -I INPUT -p tcp --dport 22 -s 100.95.0.0/16 -j ACCEPT
      iptables -A INPUT -p tcp --dport 22 -j DROP
    '';
    extraStopCommands = ''
      iptables -D INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 22 -s 192.168.178.0/24 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 22 -s 100.95.0.0/16 -j ACCEPT || true
      iptables -D INPUT -p tcp --dport 22 -j DROP || true
    '';
  };
}
