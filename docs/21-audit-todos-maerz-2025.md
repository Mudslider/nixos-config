# Audit-Ergebnisse und offene TODOs (15. März 2025)

## Immich — Thumbnail-SSD-Caching (nach DB-Rebuild)

### Funktionsweise nach `nrs`

Immich nutzt zwei getrennte Speicherpfade:

| Daten | Speicherort | Zweck |
|-------|-------------|-------|
| Originale, Library, Videos | `/tank/photos/` (HDD) | Langzeitspeicher, nur bei Vollbild-Ansicht nötig |
| Thumbnails | `/srv/ssd-buffer/immich-thumbs/` (SSD) | Schnelles Browsen ohne HDD-Spinup |
| Externe Bibliothek | `/tank/photos/extern/` (HDD, read-only) | 752GB importierte Fotos |

Container-Volume-Mounts im `immich-server`:
```
/tank/photos:/usr/src/app/upload
/srv/ssd-buffer/immich-thumbs:/usr/src/app/upload/thumbs
/tank/photos/extern:/mnt/extern:ro
```

Der SSD-Mount für Thumbnails überlagert das HDD-Verzeichnis `/tank/photos/thumbs/` innerhalb des Containers.

### Einmalige Migration nach `nrs` (auf dem Homeserver)

```bash
# Bestehende Thumbnails von HDD auf SSD kopieren
sudo rsync -avh /tank/photos/thumbs/ /srv/ssd-buffer/immich-thumbs/

# Prüfen ob Immich die Thumbnails findet
sudo podman logs --tail 20 immich-server
```

### Nightly-Sync Backup

Thumbnails werden nächtlich auf HDD gesichert:
```
/srv/ssd-buffer/immich-thumbs/ → /tank/photos/thumbs-backup/
```

Bei SSD-Ausfall: Thumbnails aus `/tank/photos/thumbs-backup/` wiederherstellen, oder Immich generiert sie neu (dauert bei 752GB+ einige Stunden).

## Immich DB-Passwort — SOPS-Migration (nach DB-Rebuild)

Das Postgres-Passwort (`immich`) lag bisher im Klartext in `immich.nix`. Jetzt über SOPS:

- Secret: `immich-db-password` in `secrets/secrets.yaml`
- Wird via SOPS-Templates als Env-Datei injiziert (`immich-postgres-env`, `immich-server-env`)
- Aktueller Wert ist `immich` (kompatibel mit bestehender DB)
- **Nach Stabilisierung:** Passwort in SOPS ändern, dann Container neu starten

Passwort ändern:
```bash
# Auf dem Laptop:
sops secrets/secrets.yaml
# → immich-db-password auf neues Passwort ändern

# Dann nrs auf dem Homeserver — startet Container mit neuem Passwort neu
# ACHTUNG: Postgres muss das Passwort auch intern kennen!
# Vor dem Passwort-Wechsel im Container:
sudo podman exec immich-postgres psql -U immich -c "ALTER USER immich PASSWORD 'neues-passwort';"
```

## Grafana secret_key — automatisch generiert

Neuer systemd-Oneshot `grafana-secret-key` generiert den Key automatisch vor Grafana-Start, falls die Datei `/srv/ssd-buffer/services/grafana/secret_key` fehlt. Keine manuelle Aktion nötig.

## Nightly-Sync Änderungen

### Fotos: Copy + Age-Out statt Move
- Fotos werden auf HDD **kopiert** (nicht verschoben)
- Dateien >90 Tage werden nur von der SSD gelöscht
- HDD behält alles, SSD hat die letzten 3 Monate

### Paperless: Backup statt Move
- Dokumente-Move-Block entfernt (Datenverlust-Risiko)
- Stattdessen: nächtliches rsync-Backup auf HDD
  - `/srv/ssd-buffer/services/paperless/` → `/tank/paperless-backup/services/`
  - `/srv/ssd-buffer/documents/` → `/tank/paperless-backup/consume/`

### HDD-Wakeup
- Hardcoded `ata-WDC_WD*` Glob ersetzt durch automatische ZFS-Pool-Device-Erkennung

## Checkliste — vor und nach `nrs`

### Voraussetzungen (ALLE müssen erfüllt sein)
- [ ] Immich DB-Rebuild ist abgeschlossen (Scan-Job fertig)
- [ ] Änderungen committed und gepusht
- [ ] `git pull` auf dem Homeserver (oder `nrs` macht das automatisch)

### Nach `nrs` auf dem Homeserver
- [ ] Thumbnails von HDD auf SSD kopieren: `sudo rsync -avh /tank/photos/thumbs/ /srv/ssd-buffer/immich-thumbs/`
- [ ] Immich testen: Browsen funktioniert, Thumbnails laden
- [ ] Grafana testen: `https://grafana.home.lan` erreichbar, secret_key generiert
- [ ] Paperless testen: Dokument hochladen, Import prüfen
- [ ] Nightly-Sync manuell testen: `sudo systemctl start nightly-sync` (tagsüber, HDDs laufen kurz an)

### Später (nicht dringend)
- [ ] Immich DB-Passwort in SOPS auf sicheres Passwort ändern (siehe oben)
- [ ] Prüfen ob SSD-Platz für Thumbnails reicht (`df -h /srv/ssd-buffer/`)
- [ ] `/etc/hosts` auf Laptop bereinigen (temporäre Hotel-Einträge entfernen)
