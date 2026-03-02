# 07 — Jellyfin (Medienserver)

Filme, Serien, Musik mit Intel Quick Sync Hardware-Transcoding.

Voraussetzung: ZFS-Pool (01) mit `/tank/media`.

---

## Schritt 1: Medien-Verzeichnisse prüfen

**Server:**

```bash
ls /tank/media/
# Sollte enthalten: filme, serien, musik, audiobooks, podcasts
```

Falls nicht:

```bash
mkdir -p /tank/media/{filme,serien,musik,audiobooks,podcasts}
sudo chown -R philip:philip /tank/media
```

## Schritt 2: Dienst aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
```

`./jellyfin.nix` einkommentieren.

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 3: Erster Login

1. **Laptop/Browser:** `https://jellyfin.home.lan`
2. Setup-Wizard: Sprache Deutsch, Benutzer philip, Passwort setzen

## Bibliotheken hinzufügen

Dashboard → Bibliotheken:

| Bibliothek | Typ | Pfad |
|------------|-----|------|
| Filme | Filme | `/tank/media/filme` |
| Serien | Sendungen | `/tank/media/serien` |
| Musik | Musik | `/tank/media/musik` |

### Dateistruktur

```
/tank/media/filme/
├── Der Film (2024)/
│   └── Der Film (2024).mkv

/tank/media/serien/
├── Serienname (2024)/
│   ├── Season 01/
│   │   ├── S01E01 - Titel.mkv
│   │   └── S01E02 - Titel.mkv
```

## Hardware-Transcoding aktivieren

Dashboard → Wiedergabe → Transkodierung:
- Hardware-Beschleunigung: **Intel QuickSync (QSV)**
- Dekodierung: H.264, HEVC, VP9, AV1 aktivieren
- Hardware-Enkodierung: Ja

**Server:** Prüfen (während eines Streams):
```bash
sudo intel_gpu_top
# GPU-Auslastung sollte sichtbar sein
```

## Medien auf den Server kopieren

**Laptop:**

```bash
# Per rsync (empfohlen für große Mengen):
rsync -avhP /lokaler/pfad/filme/ philip@192.168.1.10:/tank/media/filme/

# Per Samba (Windows Explorer): \\192.168.1.10\media
```

**Server:** Samba-Passwort einmalig setzen:
```bash
sudo smbpasswd -a philip
```

## Clients

Jellyfin-App gibt es für Android, iOS, Android TV, Fire TV, Desktop und als Kodi-Plugin. Server-Adresse: `https://jellyfin.home.lan`

## Fehlerbehebung

**Transcoding funktioniert nicht:**

**Server:**
```bash
ls -la /dev/dri/           # Muss renderD128 + card0 zeigen
groups jellyfin             # Muss: render video
sudo journalctl -u jellyfin | grep -i "transcode\|qsv"
```
