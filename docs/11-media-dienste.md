# 11 — Audiobookshelf & Navidrome (Hörbücher & Musik)

Voraussetzung: ZFS-Pool (01) mit `/tank/media`.

---

## Audiobookshelf (Hörbücher & Podcasts)

### Aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
# ./audiobookshelf.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### Einrichten

1. **Laptop/Browser:** `https://audiobookshelf.home.lan`
2. Admin-Account erstellen: philip / Passwort
3. Bibliothek hinzufügen: Typ "Hörbuch", Pfad `/audiobooks`

### Medien ablegen

**Laptop oder Server:**

```
/tank/media/audiobooks/
├── Autor - Buchtitel/
│   ├── Kapitel 01.mp3
│   └── Kapitel 02.mp3
```

### Apps

Audiobookshelf-App (Android/iOS). Server-URL: `https://audiobookshelf.home.lan`

---

## Navidrome (Musik-Streaming)

### Aktivieren

**Server:**

```bash
nano modules/server/services/default.nix
# ./navidrome.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### Einrichten

1. **Laptop/Browser:** `https://navidrome.home.lan`
2. Admin-Account erstellen

### Musik ablegen

```
/tank/media/musik/
├── Künstler/
│   ├── Album (2024)/
│   │   ├── 01 - Titel.flac
│   │   └── 02 - Titel.flac
```

Navidrome scannt stündlich automatisch.

### Subsonic-Apps

Symfonium (Android), Amperfy (iOS), Sonixd (Desktop). Server-URL: `https://navidrome.home.lan`
