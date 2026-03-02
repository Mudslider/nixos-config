# 15 — Backup: Arbeitsrechner → Homeserver

Restic-Backup vom Windows-Arbeitsrechner über NetBird-VPN.

Voraussetzung: Secrets (02), Netzwerk (03), Restic REST Server läuft.

---

## Architektur

```
Arbeitsrechner (Windows)
  → Restic (verschlüsselt client-seitig, AES-256)
  → NetBird-Tunnel (WireGuard)
  → Homeserver /srv/ssd-buffer/backup/ (SSD, schnell)
  → Nächtlicher Sync → /tank/backup/ (ZFS encrypted, RAID1)
```

Der REST-Server läuft mit `appendOnly = true` — der Client kann nur hinzufügen, nie löschen (Ransomware-Schutz).

## Schritt 1: REST-Server prüfen

**Server:**

```bash
sudo systemctl status restic-rest-server
# Muss laufen auf Port 8100

curl http://localhost:8100
```

> **⚠ Falls der REST-Server fehlschlägt** mit `.htpasswd not found`:
> ```bash
> sudo mkdir -p /srv/ssd-buffer/backup
> sudo nix-shell -p apacheHttpd --run \
>   "htpasswd -cb /srv/ssd-buffer/backup/.htpasswd restic $(sudo cat /run/secrets/restic-repo-password)"
> sudo systemctl restart restic-rest-server
> ```
> (Siehe Doc 02, Fehler 8 — auf NixOS gibt es kein `apt-get`, nutze `nix-shell`!)

## Schritt 2: NetBird auf dem Arbeitsrechner

1. Installiere NetBird: https://netbird.io/download
2. Einloggen über die Authentik-Instanz deines Freundes
3. **Arbeitsrechner:** `ping <homeserver-netbird-ip>` (z.B. 100.64.0.1)

## Schritt 3: Restic installieren

**Arbeitsrechner (Windows PowerShell):**

```powershell
# Option A: Scoop
scoop install restic

# Option B: Manuell von https://github.com/restic/restic/releases
```

## Schritt 4: Repository initialisieren

**Arbeitsrechner:**

```powershell
set RESTIC_REPOSITORY=rest:http://100.64.0.1:8100/
set RESTIC_PASSWORD=dein-restic-passwort
restic init
```

> **⚠ Passwort:** Dasselbe Passwort wie `restic-repo-password` in den sops-Secrets. **Laptop:** `sops -d ~/nixos-config/secrets/secrets.yaml | grep restic-repo` zum Nachschauen.

## Schritt 5: Backup-Script

**Arbeitsrechner:** Erstelle `C:\Users\Philip\backup.bat`:

```batch
@echo off
echo === Restic Backup Start: %date% %time% ===

set RESTIC_REPOSITORY=rest:http://100.64.0.1:8100/
set RESTIC_PASSWORD_FILE=C:\Users\Philip\.restic-password

restic backup ^
  C:\Users\Philip\Documents ^
  C:\Users\Philip\Desktop ^
  C:\Users\Philip\Projects ^
  --exclude="*.tmp" ^
  --exclude="node_modules" ^
  --exclude=".git" ^
  --exclude="__pycache__" ^
  --verbose

restic forget ^
  --keep-daily 7 ^
  --keep-weekly 4 ^
  --keep-monthly 12 ^
  --prune

echo === Backup Ende: %date% %time% ===
pause
```

**Arbeitsrechner:** Erstelle `C:\Users\Philip\.restic-password` mit dem Restic-Passwort (eine Zeile, kein Zeilenumbruch am Ende).

## Schritt 6: Automatisierung

**Arbeitsrechner:** Windows Aufgabenplanung → Einfache Aufgabe → Täglich → `backup.bat`

## Schritt 7: Prune auf dem Server

Der Client kann wegen Append-Only nicht löschen. Prune muss auf dem Server passieren.

**Server:** In `modules/server/storage/backup.nix` den `restic-prune`-Block einkommentieren (läuft Sonntags 4 Uhr):

```bash
nano modules/server/storage/backup.nix
# Den auskommentierten systemd.services.restic-prune Block aktivieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Wiederherstellung testen

**Arbeitsrechner:**

```powershell
set RESTIC_REPOSITORY=rest:http://100.64.0.1:8100/
set RESTIC_PASSWORD_FILE=C:\Users\Philip\.restic-password
restic snapshots
restic restore latest --target C:\Restore\ --include "Documents/wichtig.docx"
```

> **⚠ Disaster Recovery Test:** Mindestens 1× im Quartal eine Wiederherstellung testen!
