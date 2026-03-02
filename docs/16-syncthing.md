# 16 — Syncthing (Datei-Synchronisation)

Optional — P2P-Synchronisation zwischen Geräten. Falls Nextcloud ausreicht, brauchst du das nicht.

Voraussetzung: Netzwerk (03).

---

## Aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
# ./syncthing.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Web-UI

Syncthing lauscht nur auf localhost. Zugriff per SSH-Tunnel:

**Laptop:**

```bash
ssh -L 8384:localhost:8384 philip@192.168.1.10
```

Dann im **Laptop/Browser:** `http://localhost:8384`

> **⚠ Kein HTTPS hier** — der SSH-Tunnel verschlüsselt den Traffic bereits.

## Geräte verbinden

1. **Laptop/Handy:** Syncthing installieren
2. Device-ID austauschen (in der Web-UI beider Geräte)
3. Ordner zum Teilen auswählen
