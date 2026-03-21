# ── Firewall (Heimnetz + NetBird VPN) ──────────────────────
{ ... }:
{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80         # Caddy HTTP — für NetBird-Clients (WireGuard-Tunnel)
      443        # Caddy HTTPS — für LAN-Clients
      8100       # Restic REST-Server (htpasswd-geschützt, append-only)
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
