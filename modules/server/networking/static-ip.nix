# ── Statische IP-Konfiguration ──────────────────────────────
{ ... }:
{
  networking = {
    useDHCP = false;
    interfaces.enp1s0 = {
      ipv4.addresses = [{
        address = "192.168.178.10";
        prefixLength = 24;
      }];
    };

    defaultGateway = "192.168.178.1";
    nameservers = [
      "192.168.178.1"   # FritzBox DNS
      "1.1.1.1"         # Fallback: Cloudflare
    ];

    domain = "home.lan";
  };
}
