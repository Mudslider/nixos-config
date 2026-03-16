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

      # Auf LAN und NetBird-Interface hören (damit der Laptop von unterwegs home.lan auflösen kann)
      interface = [ "enp1s0" "wt0" ];
      bind-interfaces = true;

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
