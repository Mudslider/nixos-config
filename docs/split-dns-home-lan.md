# Split-DNS für home.lan (unterwegs)

## Problem

`home.lan`-Dienste (Grafana, Paperless, Immich etc.) sind nur über Caddy erreichbar,
der per DNS-Namen angesprochen wird. Dnsmasq auf dem Homeserver löst `*.home.lan`
auf `192.168.178.10` auf — aber nur im Heimnetz.

Unterwegs (Gast-WLAN, Hotel, Handy-Hotspot) bekommt der Laptop einen fremden
DNS-Server per DHCP, der `home.lan` nicht kennt. NetBird (WireGuard) ist zwar aktiv
und stellt die Verbindung zum Homeserver her, aber DNS scheitert.

## Dauerhafte Lösung: Split-DNS via systemd-resolved

### Homeserver — dnsmasq auf NetBird-Interface lauschen lassen

`modules/server/networking/dns.nix`:
```nix
interface = [ "enp1s0" "wt0" ];  # wt0 = NetBird-Interface
```

Der Homeserver beantwortet DNS-Anfragen nun auch über seine NetBird-IP `100.95.103.67`.

### Laptop — systemd-resolved mit Routing-Domain

`hosts/thinkpad-p15/default.nix`:
```nix
networking.networkmanager.dns = "systemd-resolved";

services.resolved = {
  enable = true;
  settings.Resolve = {
    DNS = "100.95.103.67";
    Domains = "~home.lan";  # ~ = Routing-Domain (kein Search-Suffix)
  };
};
```

Das `~` vor `home.lan` bedeutet: Anfragen für `home.lan` werden an `100.95.103.67`
weitergeleitet, alle anderen DNS-Anfragen gehen weiterhin an den DHCP-DNS.
Der Laptop-Traffic zu den Diensten selbst läuft weiter direkt über LAN (zuhause)
oder NetBird-Tunnel (unterwegs) — nur der DNS-Query geht durch den Tunnel.

### Deploy-Reihenfolge

1. Laptop: `nrt && nrs && git add -A && git commit -m "..." && git push`
2. Homeserver: `nrs` (erst wenn Immich-Jobs nicht laufen, da dnsmasq neustartet)

### Testen

```bash
resolvectl query grafana.home.lan   # erwartet: 192.168.178.10
curl https://grafana.home.lan       # erwartet: HTTP-Antwort
```

---

## Temporärer Workaround: /etc/hosts via NixOS-Config

Solange der Split-DNS noch nicht auf dem Homeserver aktiv ist (dnsmasq hört noch
nicht auf `wt0`), kann der Laptop die Auflösung über `/etc/hosts` erzwingen.

Da NixOS `/etc/hosts` verwaltet, erfolgt das über die Config:

`hosts/thinkpad-p15/default.nix`:
```nix
networking.hosts."100.95.103.67" = [
  "grafana.home.lan"
  "paperless.home.lan"
  "immich.home.lan"
  "nextcloud.home.lan"
  "backrest.home.lan"
  "uptime-kuma.home.lan"
  "vaultwarden.home.lan"
];
```

### Rollback des Workarounds

Sobald der Homeserver `nrs` mit dem neuen dnsmasq-Config gefahren hat:

1. Den `networking.hosts`-Block aus `hosts/thinkpad-p15/default.nix` entfernen
2. `nrt && nrs` auf dem Laptop
3. Testen: `resolvectl query grafana.home.lan` (muss weiterhin funktionieren, nun via DNS)
4. Committen und pushen

Den Block **nicht committen** — er ist temporär und hat in der Git-History nichts verloren.
