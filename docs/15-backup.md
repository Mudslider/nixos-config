# Backup einrichten: Arbeitsrechner → Homeserver

Restic-Backup vom Windows-Arbeitsrechner über NetBird-VPN auf den Homeserver.

## Architektur

```
Arbeitsrechner (Win 11)
  → Restic (verschlüsselt Daten client-seitig)
  → NetBird-Tunnel (WireGuard P2P, verschlüsselt Transport)
  → Homeserver /srv/ssd-buffer/backup/ (SSD, schnell)
  → Nächtlicher Sync → /tank/backup/ (ZFS encrypted, RAID1)
```

Drei Verschlüsselungsebenen:
1. **Restic:** AES-256 (Passwort bleibt auf dem Client)
2. **NetBird:** WireGuard (ChaCha20-Poly1305)
3. **ZFS:** AES-256-GCM auf den HDDs

## Schritt 1: Restic REST-Server prüfen

Auf dem **Homeserver**:

```bash
sudo systemctl status restic-rest-server
# Muss laufen auf Port 8100

# Test:
curl http://localhost:8100
```

Der REST-Server läuft mit `appendOnly = true` — der Client kann Daten nur hinzufügen, nie löschen. Das schützt vor Ransomware.

## Schritt 2: NetBird auf dem Arbeitsrechner

1. Installiere NetBird: https://netbird.io/download
2. Logge dich mit dem Account ein (über die Authentik-Instanz deines Freundes)
3. Prüfe Verbindung: `ping <homeserver-netbird-ip>`

Notiere die NetBird-IP des Homeservers (z.B. `100.64.0.1`).

## Schritt 3: Restic auf Windows installieren

```powershell
# Option A: Scoop
scoop install restic

# Option B: Manuell
# Download von https://github.com/restic/restic/releases
# restic.exe in einen Ordner legen und zum PATH hinzufügen
```

## Schritt 4: Repository initialisieren

```powershell
# Einmalig: Repository erstellen
set RESTIC_REPOSITORY=rest:http://100.64.0.1:8100/
set RESTIC_PASSWORD=dein-restic-passwort

restic init
```

**Wichtig:** Benutze dasselbe Passwort, das in deinen sops-Secrets als `restic-repo-password` steht.

## Schritt 5: Backup-Script erstellen

Erstelle `C:\Users\Philip\backup.bat`:

```batch
@echo off
echo === Restic Backup Start: %date% %time% ===

set RESTIC_REPOSITORY=rest:http://100.64.0.1:8100/
set RESTIC_PASSWORD_FILE=C:\Users\Philip\.restic-password

REM === Backup ===
restic backup ^
  C:\Users\Philip\Documents ^
  C:\Users\Philip\Desktop ^
  C:\Users\Philip\Projects ^
  --exclude="*.tmp" ^
  --exclude="node_modules" ^
  --exclude=".git" ^
  --exclude="__pycache__" ^
  --verbose

REM === Alte Snapshots aufräumen ===
restic forget ^
  --keep-daily 7 ^
  --keep-weekly 4 ^
  --keep-monthly 12 ^
  --prune

echo === Backup Ende: %date% %time% ===
pause
```

Erstelle `C:\Users\Philip\.restic-password` mit dem Restic-Passwort (eine Zeile, kein Zeilenumbruch am Ende).

## Schritt 6: Automatisierung (Windows Aufgabenplanung)

1. Öffne **Aufgabenplanung** (Task Scheduler)
2. Aktion → Einfache Aufgabe erstellen
3. Name: `Restic Backup`
4. Trigger: Täglich, 12:00 Uhr (oder wann der Rechner läuft)
5. Aktion: Programm starten → `C:\Users\Philip\backup.bat`
6. Unter Eigenschaften: "Unabhängig von Benutzeranmeldung ausführen"

## Schritt 7: Backup testen

```powershell
# Snapshots anzeigen:
set RESTIC_REPOSITORY=rest:http://100.64.0.1:8100/
set RESTIC_PASSWORD_FILE=C:\Users\Philip\.restic-password

restic snapshots

# Einzelne Datei wiederherstellen:
restic restore latest --target C:\Restore\ --include "Documents/wichtig.docx"

# Kompletten Snapshot wiederherstellen:
restic restore latest --target C:\Restore\
```

## Prune auf dem Server (gegen Ransomware)

Der Client kann wegen `appendOnly = true` keine Snapshots löschen. Prune muss auf dem Server passieren:

```bash
# Auf dem Homeserver (manuell oder als Cron):
sudo restic -r /srv/ssd-buffer/backup/ forget \
  --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune \
  --password-file /run/secrets/restic-repo-password
```

Optional als Timer in NixOS (`modules/server/storage/backup.nix`):

```nix
systemd.services.restic-prune = {
  description = "Restic Repository aufräumen";
  serviceConfig = {
    Type = "oneshot";
    ExecStart = "${pkgs.restic}/bin/restic -r /srv/ssd-buffer/backup/ forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune --password-file /run/secrets/restic-repo-password";
  };
};
systemd.timers.restic-prune = {
  wantedBy = [ "timers.target" ];
  timerConfig = {
    OnCalendar = "Sun 04:00";
    Persistent = true;
  };
};
```

## Disaster Recovery Test

Mach regelmäßig (mindestens 1× im Quartal) einen Wiederherstellungstest:

```powershell
# Zufällige Datei aus dem Backup wiederherstellen:
restic ls latest | findstr "Documents" | head -5
restic restore latest --target C:\Temp\restore-test\ --include "Documents/ein-dokument.pdf"
# Prüfe ob die Datei korrekt ist!
```

## Fehlerbehebung

### "Connection refused" beim Backup

```bash
# NetBird-Tunnel aktiv?
netbird status

# REST-Server erreichbar?
curl http://100.64.0.1:8100/
```

### "Append only mode: delete/prune not allowed"

Das ist Absicht! Prune nur vom Server aus (siehe oben).
