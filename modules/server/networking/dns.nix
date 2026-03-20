{ ... }:

{
  # ── Lokaler DNS-Resolver (dnsmasq) ────────────────────────
  # Löst *.home.lan auf den Homeserver auf.
  # Alle anderen Anfragen werden an die FritzBox weitergeleitet.
  # FritzBox DHCP muss 192.168.178.10 als DNS-Server ausgeben:
  #   Heimnetz → Netzwerk → IPv4-Einstellungen → Lokaler DNS-Server

  services.dnsmasq = {
    enable = true;
    settings = {
      # Upstream: FritzBox, Cloudflare als Fallback
      server = [ "192.168.178.1" "1.1.1.1" ];

      # Alle *.home.lan Adressen auf den Homeserver
      address = "/home.lan/192.168.178.10";

      # Auf LAN-IP und NetBird-IP hören
      # bind-dynamic: toleriert dass NetBird-IP beim Boot noch nicht existiert
      # local-service=false: NetBird-Clients haben andere Subnetz-IPs als die
      # Interface-IP — ohne diesen Flag verweigert dnsmasq die Antwort (REFUSED).
      # Sicher, weil nur auf expliziten IPs gebunden + NetBird hat nur auth. Peers.
      listen-address = [ "192.168.178.10" "100.95.103.67" "127.0.0.1" ];
      bind-dynamic = true;
      local-service = false;

      # Kein DNS-Rebind-Schutz für home.lan (private Domain)
      rebind-domain-ok = "home.lan";

      # Cache
      cache-size = 1000;
    };
  };

  # Port 53 im LAN öffnen
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
