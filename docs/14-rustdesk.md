# 14 — RustDesk (Remote Desktop)

Open-Source Remote-Desktop mit eigenem Relay-Server.

Voraussetzung: Netzwerk (03).

---

## Aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
# ./rustdesk.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Public Key ermitteln

**Server:**

```bash
sudo podman exec rustdesk-hbbs cat /root/id_ed25519.pub
# Diesen Key brauchst du für alle Clients!
```

> **⚠ Falls der Container noch nicht bereit ist:** `sudo podman ps | grep rustdesk` prüfen, ggf. 1 Minute warten.

## Clients einrichten

Installiere RustDesk (https://rustdesk.com/) auf allen Geräten und trage unter Einstellungen → Netzwerk → ID/Relay Server ein:

| Feld | Wert |
|------|------|
| ID Server | `192.168.1.10` (LAN) oder NetBird-IP (Remote) |
| Relay Server | `192.168.1.10` (LAN) oder NetBird-IP (Remote) |
| Key | Public Key von oben |
