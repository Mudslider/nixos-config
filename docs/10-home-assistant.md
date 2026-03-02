# 10 — Home Assistant (Smart Home)

Voraussetzung: Netzwerk (03).

---

## Schritt 1: ssd-buffer.nix vorbereiten

**Server:** `ssd-buffer.nix` referenziert den User `hass`, der erst durch Home Assistant erstellt wird:

```bash
nano modules/server/storage/ssd-buffer.nix
```

Temporär ändern:

```nix
# Vorher:
"d /srv/ssd-buffer/services/hass         0750 hass      hass      -"
# Nachher (temporär):
"d /srv/ssd-buffer/services/hass         0750 root root -"
```

## Schritt 2: Dienst aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
# ./home-assistant.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
# Erster Start: 3-5 Minuten (Python-Abhängigkeiten werden kompiliert)
```

> **⚠ Geduld:** Beim ersten Start kompiliert NixOS Python-Pakete. `sudo journalctl -u home-assistant -f` zeigt den Fortschritt.

## Schritt 3: ssd-buffer.nix korrigieren

**Server:** User `hass` existiert jetzt:

```bash
nano modules/server/storage/ssd-buffer.nix
# Zurück auf: "d /srv/ssd-buffer/services/hass 0750 hass hass -"

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 4: Erster Login

1. **Laptop/Browser:** `https://hass.home.lan`
2. Onboarding-Wizard: Benutzer anlegen, Standort setzen

## Integrationen

Einstellungen → Geräte & Dienste → Integration hinzufügen:
- **Fritz!Box** (Smart Home, WLAN-Tracking)
- **Meteorologisk institutt** (Wetter, oft vorkonfiguriert)

Für zusätzliche Integrationen: **Server:** `extraComponents` in `modules/server/services/home-assistant.nix` erweitern und rebuild.

## Fehlerbehebung

**"Unable to connect":** Beim ersten Start bis zu 10 Minuten warten.

**Server:**
```bash
sudo journalctl -u home-assistant -f
```
