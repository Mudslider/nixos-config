# NetBird Setup — Laptop (ThinkPad P15)

Einmalige Einrichtung für SSH-Fernzugriff auf den Homeserver von überall.

## Voraussetzungen

- NetBird-Daemon läuft als systemd-Service (`systemd.services.netbird` in NixOS-Config)
- Setup-Key aus app.netbird.io (unter Setup Keys → neuen Key erstellen)

---

## Einmalige Einrichtung

### 1. Alten NetBird-State löschen (falls vorhanden)

```bash
sudo systemctl stop netbird
sudo rm -rf /var/lib/netbird/
sudo systemctl start netbird
```

### 2. Mit NetBird-Netzwerk verbinden

```bash
sudo netbird up --setup-key <SETUP-KEY>
```

### 3. Im NetBird-Dashboard (app.netbird.io)

1. **Peers** → neuen Peer (erscheint als `playground-xxx` oder `Polly`) in die Gruppe **Philip_Server** hinzufügen
2. **Access Control → Policies** → Policy muss `Philip_Server` ↔ `Philip_Server` erlauben (bereits eingerichtet)

### 4. Verbindung prüfen

```bash
netbird status --detail
# homeserver sollte als "Connected" erscheinen
```

---

## Tägliche Nutzung

NetBird startet automatisch beim Booten. Nach einem Neustart des Laptops:

```bash
# Verbindung herstellen (falls nicht automatisch):
sudo netbird up

# Status prüfen:
netbird status

# SSH auf Homeserver:
ssh homeserver          # direkt über NetBird (empfohlen)
ssh homeserver-via-vps  # Fallback über VPS 157.90.239.236
```

---

## Troubleshooting

**Peers count: 0/0:**
```bash
sudo netbird down && sudo netbird up
# Falls immer noch 0: Dashboard prüfen ob Peer in Philip_Server Gruppe ist
```

**"peer login has expired":**
```bash
sudo systemctl stop netbird
sudo rm -rf /var/lib/netbird/
sudo systemctl start netbird
sudo netbird up --setup-key <NEUER-KEY>
# Neuen Key in app.netbird.io unter Setup Keys erstellen
# Alten Peer im Dashboard löschen, neuen in Philip_Server Gruppe hinzufügen
```

**Daemon nicht gestartet ("connection refused"):**
```bash
sudo systemctl status netbird
sudo systemctl restart netbird
```

---

## Bekannte Einschränkungen

- `services.netbird.enable` ist in nixpkgs 26.05 kaputt (netbird 0.65.3 wrapper bug) → daher manueller systemd-Service in `hosts/thinkpad-p15/default.nix`
- DNS für `home.lan` funktioniert über NetBird nicht (WireGuard-Key-Problem) — `ssh homeserver` über IP funktioniert aber einwandfrei
- Setup-Key in SOPS (`netbird-setup-key`) ist der Key für den **Homeserver**, nicht für den Laptop — für den Laptop immer neuen Key in app.netbird.io erstellen
