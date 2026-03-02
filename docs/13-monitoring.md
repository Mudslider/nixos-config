# 13 — Monitoring (Uptime Kuma & Netdata)

Voraussetzung: Netzwerk (03).

---

## Uptime Kuma (Verfügbarkeits-Monitoring)

### Aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
# ./uptime-kuma.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### Einrichten

1. **Laptop/Browser:** `https://status.home.lan`
2. Admin-Account erstellen

### Monitore hinzufügen

Für jeden Dienst "Neuer Monitor" → Typ HTTPS → URL eintragen (z.B. `https://nextcloud.home.lan`). Intervall: 60 Sekunden reicht.

> **⚠ TLS-Fehler:** Uptime Kuma vertraut der Caddy-CA nicht automatisch. Bei HTTPS-Monitoren "Ignore TLS" aktivieren, da alles intern läuft.

### Benachrichtigungen (optional)

Einstellungen → Benachrichtigungen: Telegram-Bot, E-Mail oder Gotify.

---

## Netdata (System-Metriken)

### Aktivieren

**Server:**

```bash
nano modules/server/services/default.nix
# ./netdata.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### Dashboard

**Laptop/Browser:** `https://netdata.home.lan` — Hunderte Metriken in Echtzeit: CPU, RAM, Disk I/O, Netzwerk, ZFS ARC, SMART, Systemd-Dienste, CPU-Temperatur.

### Wichtige Dashboards

- **System Overview:** CPU, RAM, Disk, Netz auf einen Blick
- **Disks:** I/O pro Platte (NVMe vs. HDD)
- **ZFS:** ARC-Effizienz, Compression-Ratio
- **Sensors:** CPU-Temperatur
