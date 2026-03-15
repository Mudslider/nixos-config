# 20 — Sicherheits-Audit Protokoll

Systematische Überprüfung von Bugs und Sicherheitslücken auf allen drei Maschinen.
Vor jedem Audit: `git pull` auf dem Laptop, `nrs` auf allen Maschinen sicherstellen.

---

## Vorbereitung

```bash
# Laptop: aktuellen Stand holen
cd ~/nixos-config
git pull

# Von welchem System aus du arbeitest:
# - Homeserver-Befehle: ssh homeserver
# - VPS-Befehle: ssh vps
# - Laptop-Befehle: lokal
```

---

## 1 — Netzwerk: Offene Ports

### 1.1 VPS (öffentlich erreichbar)

```bash
# Welche Ports sind von außen offen?
ssh vps "ss -tlnp"

# Erwartete Ports:
#   :22   — SSH (öffentlich, Fail2ban aktiv)
#   :80   — Caddy HTTP (ACME-Challenge)
#   :443  — Caddy HTTPS
#   :51820 — WireGuard/NetBird (UDP)

# Von außen scannen (vom Laptop aus):
nmap -sV 157.90.239.236
# Darf NUR 22, 80, 443 (TCP) + 51820 (UDP) zeigen
```

**Checkliste VPS:**
- [ ] Keine unerwarteten offenen Ports
- [ ] SSH nur auf Port 22 (nicht 2222 oder ähnliches)
- [ ] Kein direkter Datenbankport offen (5432, 3306, 6379 etc.)

### 1.2 Homeserver (LAN + NetBird)

```bash
ssh homeserver "ss -tlnp"

# Erwartete Ports (nur intern):
#   :22   — SSH (nur LAN 192.168.x und NetBird 100.95.x)
#   :80   — Caddy HTTP (für NetBird-Clients)
#   :443  — Caddy HTTPS (LAN)
#   :8100 — Restic REST-Server (nur NetBird-Interface 100.95.103.67)
#   :8222 — Vaultwarden (nur localhost)
#   :2283 — Immich (nur localhost)
#   :8000 — Paperless (nur localhost)
#   :8080 — Nextcloud (nur localhost)
#   :3001 — Uptime Kuma (nur localhost)
#   :3100 — Grafana (nur localhost, IPv4)
#   :9898 — Backrest (nur localhost)
#   :8084 — ntfy (nur localhost)

# Firewall-Regeln prüfen:
ssh homeserver "sudo iptables -L INPUT -n --line-numbers"
# Port 22 darf NUR von 192.168.1.0/24, 192.168.178.0/24 und 100.95.0.0/16 erreichbar sein
```

**Checkliste Homeserver:**
- [ ] Kein Dienst-Port direkt von außen erreichbar (nur über Caddy)
- [ ] Restic REST-Server lauscht nur auf NetBird-IP (nicht 0.0.0.0)
- [ ] SSH-Drop-Rule aktiv: `iptables -L INPUT -n | grep "DROP.*dpt:22"`
- [ ] Temporäre Regel `192.168.178.0/24` für SSH: prüfen ob noch nötig (war pfSense-Workaround)

### 1.3 Laptop

```bash
# Offene Ports:
ss -tlnp
# Erwartet: :22 (SSH, falls services.openssh.enable = true)

# SSH-Dienst auf Laptop nötig?
# Wenn nicht, in hosts/thinkpad-p15/default.nix deaktivieren:
# services.openssh.enable = false;
```

---

## 2 — Authentifizierung

### 2.1 SSH-Konfiguration

```bash
# Homeserver: SSH-Einstellungen prüfen
ssh homeserver "sudo sshd -T | grep -E 'passwordauthentication|permitemptypasswords|permitrootlogin|pubkeyauthentication|allowtcpforwarding'"

# Soll:
#   passwordauthentication no
#   permitemptypasswords no
#   permitrootlogin no
#   pubkeyauthentication yes

# VPS:
ssh vps "sudo sshd -T | grep -E 'passwordauthentication|permitrootlogin'"
# VPS hat root-Login — prüfen ob das noch nötig ist (root ist einziger User auf VPS)
```

**Checkliste SSH:**
- [ ] Homeserver: `PasswordAuthentication no`
- [ ] Homeserver: `PermitRootLogin no`
- [ ] VPS: `PasswordAuthentication no`
- [ ] Authorized Keys korrekt? Keine alten/unbekannten Keys?

```bash
# Authorized Keys prüfen:
ssh homeserver "cat ~/.ssh/authorized_keys"
ssh vps "cat ~/.ssh/authorized_keys"
```

### 2.2 SOPS-Secrets hygiene

```bash
# Alle Secrets auflisten:
cd ~/nixos-config
sops --decrypt secrets/secrets.yaml | grep -v "^#" | cut -d: -f1

# Für jeden Secret fragen:
# - Wird er noch benutzt?
# - Ist er stark genug? (min. 32 Zeichen Entropie für Passwörter)
# - Liegt der Klartext irgendwo in git?
```

**Bekannte Schwachstellen (zum Audit-Zeitpunkt):**
- [ ] `PAPERLESS_ADMIN_PASSWORD` — liegt noch im Klartext in git-History! Rotieren + in SOPS migrieren
- [ ] Alle Restic-Passwörter (windows, polly, nora, berlin) auf Stärke prüfen

```bash
# Git-History nach Klartext-Secrets durchsuchen:
cd ~/nixos-config
git log --all --full-history -p -- "**/*.nix" | grep -i "password\s*=\s*\"" | grep -v "#"
# Auch:
git log --all --full-history -p -- "secrets/" 2>/dev/null | head -50
```

### 2.3 Service-Passwörter

```bash
# Vaultwarden Admin-Token (SOPS):
ssh homeserver "sudo cat /run/secrets/vaultwarden-admin-token | wc -c"
# Sollte 32+ Zeichen sein

# Grafana secret_key:
ssh homeserver "cat /srv/ssd-buffer/services/grafana/secret_key 2>/dev/null | wc -c || echo 'FEHLT!'"
# Falls "FEHLT!": Datei erstellen mit: openssl rand -base64 32 > /srv/ssd-buffer/services/grafana/secret_key
```

---

## 3 — TLS / Caddy

### 3.1 VPS: Öffentliche Zertifikate (Let's Encrypt)

```bash
# Zertifikats-Ablauf prüfen:
ssh vps "sudo caddy list-certificates 2>/dev/null || echo 'caddy list-certificates nicht verfügbar'"

# Alternativ von außen:
echo | openssl s_client -connect vaultwarden.philipjonasch.de:443 -servername vaultwarden.philipjonasch.de 2>/dev/null | openssl x509 -noout -dates
echo | openssl s_client -connect immich.philipjonasch.de:443 -servername immich.philipjonasch.de 2>/dev/null | openssl x509 -noout -dates
echo | openssl s_client -connect paperless.philipjonasch.de:443 2>/dev/null | openssl x509 -noout -dates

# TLS-Konfiguration prüfen (z.B. via SSL Labs):
# https://www.ssllabs.com/ssltest/ — manuell für *.philipjonasch.de aufrufen
# Ziel: Grade A oder A+
```

**Checkliste TLS:**
- [ ] Alle Zertifikate gültig, mind. 30 Tage Restlaufzeit
- [ ] TLS 1.3 aktiv, TLS 1.0/1.1 deaktiviert (Caddy-Default: ok)
- [ ] HSTS-Header vorhanden? (`curl -I https://vaultwarden.philipjonasch.de | grep -i strict`)

### 3.2 Homeserver: Caddy interne CA

```bash
# Root-CA-Ablauf prüfen:
ssh homeserver "openssl x509 -in /var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt -noout -dates"

# Auf Laptop importiert?
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /dev/null 2>/dev/null
# Besser: direkt testen
curl -I https://vaultwarden.home.lan 2>&1 | grep -E "SSL|certificate|curl"
# Sollte kein Zertifikatsfehler kommen (wegen security.pki.certificateFiles in hosts/thinkpad-p15)
```

### 3.3 Caddy Security-Header

```bash
# Öffentliche Domains auf Security-Header prüfen:
curl -sI https://vaultwarden.philipjonasch.de | grep -iE "x-frame|x-content|strict-transport|content-security"

# Fehlende Header wären Findings. Caddy kann diese per globalConfig oder per VirtualHost setzen.
```

---

## 4 — Dienste und Container

### 4.1 Laufende Prozesse

```bash
# Homeserver: Alle aktiven Services
ssh homeserver "systemctl list-units --type=service --state=running | grep -v systemd"

# Unbekannte oder unerwartete Services?
# Podman-Container:
ssh homeserver "sudo podman ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'"

# Container-Images mit Alter:
ssh homeserver "sudo podman images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Created}}'"
# Alte Images (>3 Monate) auf Updates prüfen
```

### 4.2 Podman-Netzwerk-Isolation

```bash
# Welche Container teilen ein Netzwerk?
ssh homeserver "sudo podman network ls"
ssh homeserver "sudo podman network inspect immich_default 2>/dev/null | grep -A5 'Subnets\|Connected'"

# Container sollten KEINE direkte Bridge zum Host haben, außer bewusst konfiguriert
# Uptime Kuma nutzt host network — ist das noch nötig?
ssh homeserver "sudo podman inspect uptime-kuma 2>/dev/null | grep -i 'networkmode'"
```

### 4.3 Service-User-Rechte

```bash
# Mit welchem User laufen die Dienste?
ssh homeserver "systemctl show vaultwarden nextcloud grafana -p User,Group"
ssh homeserver "sudo podman inspect paperless-web immich-server 2>/dev/null | grep -A2 '\"User\"'"

# Kein Dienst sollte als root laufen (außer wenn zwingend nötig):
ssh homeserver "sudo podman ps -q | xargs sudo podman inspect --format '{{.Name}}: {{.Config.User}}'"
```

---

## 5 — Updates / Abhängigkeiten

### 5.1 NixOS-Updates

```bash
# Wann wurden die Flake-Inputs zuletzt aktualisiert?
cd ~/nixos-config
git log --oneline -- flake.lock | head -5
# Ältere als 4 Wochen: Update einplanen

# Verfügbare Updates anzeigen (ohne zu switchen):
nix flake update --dry-run 2>/dev/null || nix flake metadata
```

### 5.2 Podman-Image-Updates

```bash
# Verfügbare Updates für Container-Images prüfen:
ssh homeserver "sudo podman auto-update --dry-run 2>/dev/null"
# Falls kein auto-update konfiguriert: manuell für jedes Image mit aktuellem Tag vergleichen
```

### 5.3 CVE-Check

```bash
# Bekannte Schwachstellen in installierten Paketen:
# (erfordert vulnix — optional installieren)
ssh homeserver "nix-env -qa nixpkgs.vulnix 2>/dev/null && vulnix --system || echo 'vulnix nicht installiert'"

# Alternativ: NVD/CVE-Datenbanken manuell für kritische Dienste prüfen:
# - Vaultwarden (Bitwarden-kompatibel)
# - Immich
# - Paperless-NGX
# - Caddy
# - NetBird
```

---

## 6 — ZFS und Verschlüsselung

```bash
# Pool-Status:
ssh homeserver "sudo zpool status tank"
# Erwartete Checksums, keine ERRORS, ONLINE-State

# Verschlüsselung aktiv?
ssh homeserver "sudo zfs get encryption,keystatus tank"
# encryption: aes-256-gcm
# keystatus: available

# Snapshot-Übersicht (unerwartete Snapshots?):
ssh homeserver "sudo zfs list -t snapshot -o name,creation | tail -20"

# Ist der Pool importierbar ohne die Maschine? (Keyfile-Sicherheit)
# Falls Keyfile: Wer hat Zugriff auf /root/.zfs-keyfile?
ssh homeserver "sudo ls -la /root/.zfs-keyfile 2>/dev/null || echo 'Kein Keyfile (Passphrase-Modus)'"
```

---

## 7 — NetBird / VPN

```bash
# Peers: Welche Geräte sind im Netzwerk?
# → app.netbird.io: Peers-Liste manuell prüfen
# Alle Peers bekannt? Keine alten/ungenutzten Peers?

# NetBird-Policies: Nur notwendige Verbindungen erlaubt?
# → app.netbird.io: Access Control → Policies
# Aktuelle Policy: Philip_Server ↔ Philip_Server (alles erlaubt)
# Empfehlung: Später auf Port-spezifische Regeln einschränken (SSH=22, Restic=8100)

# Setup-Keys: Abgelaufene oder unnötige Keys löschen
# → app.netbird.io: Setup Keys → Audit
```

---

## 8 — Logs und Anomalien

### 8.1 Fehlgeschlagene Login-Versuche

```bash
# VPS (öffentlich erreichbar — hier am wichtigsten):
ssh vps "sudo journalctl -u sshd --since '7 days ago' | grep -i 'failed\|invalid' | wc -l"
# Viele Versuche = Fail2ban prüfen

# Fail2ban-Status:
ssh vps "sudo fail2ban-client status sshd"
# Gebannte IPs und Trefferrate anzeigen

# Homeserver:
ssh homeserver "sudo journalctl -u sshd --since '7 days ago' | grep -i 'failed' | wc -l"
```

### 8.2 Caddy-Logs

```bash
# Ungewöhnliche Anfragen an öffentliche Domains:
ssh vps "sudo journalctl -u caddy --since '24 hours ago' | grep -E '4[0-9]{2}|5[0-9]{2}' | head -30"

# Zugriffe auf /admin bei Vaultwarden (sollte 403 sein):
ssh vps "sudo journalctl -u caddy --since '7 days ago' | grep 'admin' | head -20"
```

### 8.3 Systemd-Journal auf Fehler

```bash
# Kritische Fehler der letzten Woche:
ssh homeserver "sudo journalctl -p err..crit --since '7 days ago' --no-pager | tail -50"
ssh vps "sudo journalctl -p err..crit --since '7 days ago' --no-pager | tail -20"
```

---

## 9 — Backup-Integrität

```bash
# Restic-Repos auf Konsistenz prüfen:
# (Achtung: weckt HDDs auf — wenn möglich nachts ausführen)

REPOS=("windows" "polly" "nora")
for repo in "${REPOS[@]}"; do
  echo "=== Prüfe $repo ==="
  ssh homeserver "sudo restic check \
    -r /srv/ssd-buffer/restic/$repo \
    --password-file /run/secrets/restic-password-$repo"
done

# HDD-Repos prüfen:
for repo in "${REPOS[@]}"; do
  echo "=== HDD: $repo ==="
  ssh homeserver "sudo restic check \
    -r /tank/backup/restic/$repo \
    --password-file /run/secrets/restic-password-$repo"
done
```

---

## 10 — Bekannte Baustellen (Stand Audit-Datum ausfüllen)

Diese Punkte waren beim letzten Audit bekannt und sollten zuerst angegangen werden:

| # | Problem | Schwere | Maschine | Status |
|---|---------|---------|----------|--------|
| 1 | `PAPERLESS_ADMIN_PASSWORD` liegt im Klartext in git-History | Hoch | Homeserver | Offen |
| 2 | Grafana `secret_key`-Datei existiert möglicherweise nicht | Mittel | Homeserver | Ungeprüft |
| 3 | Firewall-Regel `192.168.178.0/24` ist temporärer pfSense-Workaround | Niedrig | Homeserver | Temporär |
| 4 | SSH auf Laptop (`services.openssh.enable = true`) — nötig? | Niedrig | Laptop | Ungeprüft |
| 5 | NetBird Policy erlaubt alles — feingranulare Portregeln wären besser | Niedrig | Alle | Offen |
| 6 | Caddy Security-Header (X-Frame-Options, CSP) fehlen auf VPS | Niedrig | VPS | Offen |

---

## Checkliste (Zusammenfassung)

**Netzwerk:**
- [ ] Nmap-Scan VPS: Nur 22/80/443 TCP, 51820 UDP
- [ ] Homeserver: Kein Dienst-Port direkt erreichbar
- [ ] SSH-Drop-Regel auf Homeserver aktiv

**Auth:**
- [ ] SSH PasswordAuthentication überall `no`
- [ ] Authorized Keys geprüft (keine Altlasten)
- [ ] Paperless-Passwort in SOPS migriert
- [ ] Grafana secret_key vorhanden

**TLS:**
- [ ] Zertifikate gültig (>30 Tage)
- [ ] SSL Labs A+ für philipjonasch.de

**Dienste:**
- [ ] Keine unbekannten Prozesse/Container
- [ ] Container-Images nicht veraltet (>3 Monate)

**ZFS:**
- [ ] Pool online, keine Fehler
- [ ] Verschlüsselung aktiv

**Logs:**
- [ ] Keine kritischen Fehler
- [ ] Fail2ban aktiv und bannt

**Backup:**
- [ ] `restic check` ohne Fehler auf allen Repos
