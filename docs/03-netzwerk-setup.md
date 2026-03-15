# 03 — Netzwerk: DNS und Caddy (LAN-only)

Voraussetzung: Secrets eingerichtet (Anleitung 02), ZFS-Pool erstellt (Anleitung 01).

> **Hinweis:** Diese Anleitung konfiguriert den Server nur für den LAN-Zugriff.
> NetBird (VPN/Remote-Zugriff) wird später ergänzt, wenn eine externe Instanz
> verfügbar ist.

---

## Netzwerk-Architektur (aktuell)

```
Internet ← FritzBox (NAT/Firewall) ← Switch ← Homeserver (192.168.178.10)

Zugriff: Nur aus dem Heimnetz (192.168.178.0/24)
  Laptop → LAN → https://nextcloud.home.lan → Caddy → Dienst
```

---

## Schritt 1: DNS in pfSense

### Wildcard-DNS einrichten

In pfSense unter **Services → DNS Resolver → Custom Options**:

```
local-zone: "home.lan." redirect
local-data: "home.lan. A 192.168.178.10"
```

Das leitet **alle** `*.home.lan`-Anfragen auf den Server um — du brauchst
keinen neuen DNS-Eintrag, wenn ein neuer Dienst dazukommt.

### Prüfen

Auf dem **Laptop**:

```bash
nslookup nextcloud.home.lan
# Muss 192.168.178.10 zurückgeben

nslookup jellyfin.home.lan
# Muss ebenfalls 192.168.178.10 zurückgeben
```

Falls nicht: DNS-Server im Laptop muss auf FritzBox (192.168.178.1) zeigen.

## Schritt 2: Caddy prüfen

Caddy sollte bereits laufen (ist in der Basis-Config aktiv):

```bash
sudo systemctl status caddy
```

Falls nicht: Prüfe ob `./caddy.nix` in `modules/server/networking/default.nix` importiert wird.

## Schritt 3: Caddy Root-CA auf Clients installieren

Caddy erstellt eigene TLS-Zertifikate für `*.home.lan`. Damit Browser keine
Zertifikatswarnungen zeigen, musst du die Root-CA auf allen Clients installieren.

**Server:** Caddy erstellt die CA erst beim ersten Request. Falls die Datei
noch nicht existiert:

```bash
curl -k https://localhost:443 || true
# Jetzt sollte die CA existieren
```

**Laptop:** CA-Datei herunterladen:

```bash
scp philip@192.168.178.10:/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt ~/caddy-root-ca.crt
```

**CA installieren:**

| Plattform | Befehl |
|-----------|--------|
| Linux | `sudo cp caddy-root-ca.crt /usr/local/share/ca-certificates/caddy-homeserver.crt && sudo update-ca-certificates` |
| Windows | `certutil -addstore Root caddy-root-ca.crt` |
| macOS | `sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain caddy-root-ca.crt` |
| Android | Einstellungen → Sicherheit → Zertifikat installieren → CA-Zertifikat |
| iOS | Datei senden → Profil installieren → Einstellungen → Allgemein → Info → Zertifikatsvertrauenseinstellungen → Aktivieren |

## Schritt 4: Testen

```bash
curl https://nextcloud.home.lan
# 502 ist OK — Nextcloud läuft noch nicht, aber Caddy antwortet
```

---

## Fehlerbehebung

### DNS funktioniert nicht

```bash
# Laptop:
nslookup nextcloud.home.lan
# Falls Timeout: DNS-Server auf FritzBox (192.168.178.1) prüfen

# Server:
cat /etc/resolv.conf
# Muss 192.168.178.1 oder 1.1.1.1 enthalten
```

### Caddy startet nicht

```bash
sudo journalctl -u caddy -f
# Häufigste Ursache: Syntaxfehler in caddy.nix
```

### Zertifikatswarnungen im Browser

CA nicht installiert. Siehe Schritt 3.

---

## Später: NetBird ergänzen

Wenn du Zugriff auf eine NetBird-Instanz hast:

1. In `modules/server/security/encryption.nix`: Secret `"netbird-setup-key" = {};` hinzufügen
2. In `secrets/secrets.yaml`: `netbird-setup-key: DEIN-KEY` eintragen
3. In `modules/server/networking/default.nix`: `./netbird.nix` einkommentieren
4. In `modules/server/security/firewall.nix`:
   - `51820` zu `allowedUDPPorts` hinzufügen
   - `trustedInterfaces = [ "wt0" ];` einkommentieren
   - SSH-Regeln um NetBird-Interface erweitern
5. Rebuild: `sudo nixos-rebuild switch --flake ~/nixos-config#homeserver`

---

## Nächste Schritte

→ **Anleitungen 04-15:** Einzelne Dienste aktivieren
→ Empfohlene Reihenfolge: **08 Vaultwarden** → **04 Nextcloud** → **05 Immich** → Rest
