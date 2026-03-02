# 05 — Immich (Foto- & Video-Management)

Ersetzt Google Photos. KI-Gesichtserkennung, automatischer Handy-Upload.

Voraussetzung: ZFS-Pool (01), Netzwerk (03). Braucht `/tank/photos` und das Podman-Netzwerk `immich-net`.

---

## Schritt 1: ZFS-Dataset prüfen

**Server:**

```bash
sudo zfs list | grep photos
# Muss "tank/photos" zeigen mit Mountpoint /tank/photos
ls -la /tank/photos
```

Falls nicht vorhanden (Anleitung 01 nicht abgeschlossen):

```bash
sudo zfs create -o mountpoint=/tank/photos tank/photos
sudo chown -R philip:philip /tank/photos
```

## Schritt 2: Podman-Netzwerk prüfen

Das Netzwerk `immich-net` wird von `podman.nix` automatisch erstellt. Prüfe trotzdem:

**Server:**

```bash
sudo podman network ls | grep immich
```

Falls leer:

```bash
sudo podman network create immich-net
```

## Schritt 3: Dienst aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
```

`./immich.nix` einkommentieren.

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
# Erster Start: 3-5 Minuten (4 Container + ML-Modell ~1.5 GB Download)
```

## Schritt 4: Status prüfen

**Server:**

```bash
sudo podman ps | grep immich
# Muss 4 Container zeigen (server, ml, postgres, redis), alle "Up"
```

> **⚠ Falls Container nicht starten:** Warte 2-3 Minuten. Die Container werden beim ersten Mal heruntergeladen. Fortschritt prüfen: `sudo journalctl -u podman-immich-server -f`

## Schritt 5: Erster Login

1. **Laptop/Browser:** `https://immich.home.lan`
2. **"Getting Started"** → Admin-Account: philip / sicheres Passwort
3. Passwort in Vaultwarden speichern

## Handy-App (Auto-Upload)

1. Immich-App installieren (Play Store / App Store)
2. Server-URL: `https://immich.home.lan`
3. Backup → Automatisches Backup aktivieren

> **⚠ Voraussetzung:** Caddy Root-CA muss auf dem Handy installiert sein (Anleitung 03). Unterwegs: NetBird auf dem Handy → Auto-Upload funktioniert auch über VPN.

## Storage

| Pfad | Inhalt |
|------|--------|
| `/tank/photos` | Alle Fotos/Videos (ZFS-verschlüsselt, RAID1) |
| `immich-pgdata` | PostgreSQL-Datenbank (Podman-Volume) |
| `immich-ml-cache` | ML-Modell-Cache (Podman-Volume) |

## Fehlerbehebung

**Container starten nicht:**

**Server:**
```bash
sudo podman network ls | grep immich
# Falls leer:
sudo podman network create immich-net
sudo systemctl restart podman-immich-redis podman-immich-postgres
sleep 10
sudo systemctl restart podman-immich-server podman-immich-ml
```

**ML-Container crasht (Out of Memory):** N100 hat 32 GB RAM, sollte reichen. Falls nicht: `sudo podman logs immich-ml 2>&1 | tail -20`
