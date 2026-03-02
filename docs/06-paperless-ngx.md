# 06 — PaperlessNGX (Dokumentenmanagement)

Automatische OCR-Texterkennung für Rechnungen, Verträge, Briefe.

Voraussetzung: Netzwerk (03). Braucht Podman-Netzwerk `paperless-net`.

---

## Schritt 1: Podman-Netzwerk prüfen

**Server:**

```bash
sudo podman network ls | grep paperless
```

Falls leer: `sudo podman network create paperless-net`

## Schritt 2: Dienst aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
```

`./paperless-ngx.nix` einkommentieren.

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
# Warte 2-3 Minuten (Container + DB-Migration)
```

> **⚠ ssd-buffer.nix:** Die Einträge für Paperless nutzen `root root`, daher kein User-Problem.

## Schritt 3: Erster Login

1. **Laptop/Browser:** `https://paperless.home.lan`
2. Login: **philip** / (Passwort aus Passwort-Manager)
3. **Sofort Passwort ändern** unter Profil (oben rechts)

> **⚠ Das Passwort Das Admin-Passwort wird in der UI verwaltet.

## Dokumente importieren

### Web-UI

Hochladen-Button → Datei auswählen → Upload.

### Consume-Ordner (automatisch)

**Laptop:** Dateien per SCP hochladen:

```bash
scp rechnung.pdf philip@192.168.1.10:/srv/ssd-buffer/documents/
# Verarbeitung innerhalb von 1-2 Minuten
```

### Bulk-Import

**Server:**
```bash
cp ~/alte-dokumente/*.pdf /srv/ssd-buffer/documents/
# Bei vielen Dateien dauert das Stunden (N100 mit OCR)
```

## Korrespondenten und Tags

Unter Verwaltung: **Korrespondenten** (z.B. "Versicherung", "Finanzamt"), **Dokumenttypen** (z.B. "Rechnung", "Vertrag"), **Tags** (z.B. "Wichtig", "2025") anlegen. PaperlessNGX lernt nach ein paar manuell zugeordneten Dokumenten automatisch Muster.

## Fehlerbehebung

**Container startet nicht:**

**Server:**
```bash
sudo podman logs paperless 2>&1 | tail -20
sudo podman network ls | grep paperless
```
