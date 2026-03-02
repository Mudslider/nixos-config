# 17 — Offsite-Backup: Server → Freund

Sichert alle kritischen Server-Daten verschlüsselt auf den Server deines Freundes über NetBird-VPN.

Voraussetzung: Secrets (02), Netzwerk/NetBird (03), ZFS-Pool (01).

---

## Was wird gesichert?

| Daten | Warum kritisch? |
|-------|----------------|
| Nextcloud DB-Dump | Kalender, Kontakte, Dateimetadaten |
| Authentik DB-Dump | SSO-Benutzer und Konfiguration |
| Immich DB-Dump | Foto-Metadaten, Gesichtserkennung, Alben |
| Vaultwarden | Alle Passwörter |
| Forgejo | Git-Repos, Issues |
| PaperlessNGX | Dokumente, OCR-Daten |
| Home Assistant | Automationen, Konfiguration |
| NixOS-Config | Gesamte Server-Konfiguration |

**Nicht gesichert** (zu groß, wiederherstellbar): Fotos (`/tank/photos`), Medien (`/tank/media`).

## Voraussetzungen beim Freund

1. SSH-Benutzer für dich (z.B. `backup-philip`)
2. Verzeichnis `/backup/philip/`
3. Dein SSH-Public-Key in seinen `authorized_keys`
4. NetBird muss bei ihm laufen

## Schritt 1: Nightly-Sync aktivieren

Bevor das Offsite-Backup laufen kann, muss der nächtliche SSD→HDD-Sync aktiv sein.

**Server:**

```bash
nano modules/server/storage/default.nix
# ./nightly-sync.nix einkommentieren (falls noch nicht geschehen)

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 2: SSH-Key für Backup erstellen

**Server:**

```bash
sudo ssh-keygen -t ed25519 -f /root/.ssh/offsite-backup -N "" -C "homeserver-backup"
sudo cat /root/.ssh/offsite-backup.pub
```

Den Public Key an deinen Freund schicken — er trägt ihn in `~backup-philip/.ssh/authorized_keys` ein.

## Schritt 3: SSH-Verbindung testen

**Server:**

```bash
sudo ssh -i /root/.ssh/offsite-backup backup-philip@100.64.0.2 "echo OK"
```

> **⚠ Ersetze `100.64.0.2`** mit der NetBird-IP des Freundes.
> Beim ersten Verbinden: `The authenticity of host...` → `yes` eingeben.

## Schritt 4: offsite-backup.nix anpassen

**Server:**

```bash
nano modules/server/storage/offsite-backup.nix
```

Ersetze die Platzhalter:
- `RESTIC_REPOSITORY`: `sftp:backup-philip@100.64.0.2:/backup/philip` (mit echter NetBird-IP)
- `programs.ssh.extraConfig`: IP und User anpassen

## Schritt 5: Offsite-Backup aktivieren

**Server:**

```bash
nano modules/server/storage/default.nix
# ./offsite-backup.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 6: Repository initialisieren und testen

**Server:**

```bash
# Restic-Repo initialisieren:
sudo RESTIC_PASSWORD_FILE=/run/secrets/offsite-backup-password \
  restic -r sftp:backup-philip@100.64.0.2:/backup/philip init

# Erstes Backup manuell:
sudo systemctl start offsite-backup-pre
sudo systemctl start offsite-backup
sudo journalctl -u offsite-backup -f
```

> **⚠ Das erste Backup kann sehr lange dauern** (je nach Datenmenge und Upload-Geschwindigkeit). Timeout ist auf 6h gesetzt.

## Zeitplan

```
03:00  nightly-sync      SSD → HDD (rsync)
04:00  offsite-backup    DB-Dumps + Restic → Freund
```

**Server:** Timer prüfen:

```bash
sudo systemctl list-timers | grep -E "nightly|offsite"
```

## Wiederherstellung

**Server:**

```bash
# Snapshots anzeigen:
sudo RESTIC_PASSWORD_FILE=/run/secrets/offsite-backup-password \
  restic -r sftp:backup-philip@100.64.0.2:/backup/philip snapshots

# Einzelne Datei:
sudo RESTIC_PASSWORD_FILE=/run/secrets/offsite-backup-password \
  restic -r sftp:backup-philip@100.64.0.2:/backup/philip \
  restore latest --target /tmp/restore/ \
  --include "/srv/ssd-buffer/services/vaultwarden/db.sqlite3"
```

## Disaster Recovery (alles verloren)

1. NixOS installieren (Anleitung 00)
2. ZFS-Pool erstellen (Anleitung 01)
3. Secrets wiederherstellen (Age-Key vom **Laptop** nötig!)
4. Offsite-Backup komplett wiederherstellen:
   **Server:** `sudo restic restore latest --target /`
5. Datenbank-Dumps importieren:
   **Server:**
   ```bash
   sudo -u postgres psql nextcloud < /srv/ssd-buffer/services/db-dumps/nextcloud.sql
   sudo podman exec -i authentik-postgres psql -U authentik authentik < /srv/ssd-buffer/services/db-dumps/authentik.sql
   sudo podman exec -i immich-postgres psql -U immich immich < /srv/ssd-buffer/services/db-dumps/immich.sql
   ```
6. Dienste starten und prüfen

> **⚠ Kritisch:** Ohne den Age-Key vom Laptop kannst du die sops-Secrets nicht wiederherstellen! Sichere `~/.config/sops/age/keys.txt` vom **Laptop** zusätzlich offline (z.B. Papier-Backup, USB-Stick im Safe).
