# Fernzugriff per SSH auf den Homeserver

## Voraussetzungen

- ThinkPad P15 mit laufendem NetBird-Daemon (`services.netbird.enable = true`)
- NetBird einmalig aktiviert (`sudo netbird up`)

---

## Methode 1: Direkt über NetBird (empfohlen)

NetBird baut einen verschlüsselten P2P-Tunnel auf — funktioniert von überall mit Internetzugang.

```bash
# Einmalig beim ersten Mal (oder nach Neuinstallation):
sudo netbird up

# Verbinden:
ssh homeserver
# entspricht: ssh philip@100.95.103.67
```

NetBird-Status prüfen:
```bash
netbird status
```

---

## Methode 2: Über VPS als Sprunghost (Fallback)

Falls NetBird nicht verfügbar ist (z.B. NetBird-Koordinationsserver nicht erreichbar):

```bash
ssh homeserver-via-vps
# entspricht: ssh -J root@157.90.239.236 philip@100.95.103.67
```

Der VPS hat eine öffentliche IP und erreicht den Homeserver über den NetBird-Tunnel.

---

## SSH-Aliase (in ~/.ssh/config hinterlegt)

| Alias | Ziel | Über |
|-------|------|------|
| `ssh homeserver` | 100.95.103.67 (philip) | NetBird direkt |
| `ssh homeserver-via-vps` | 100.95.103.67 (philip) | VPS 157.90.239.236 |
| `ssh vps` | 157.90.239.236 (root) | direkt |

---

## Troubleshooting

**NetBird verbindet nicht:**
```bash
sudo systemctl restart netbird
netbird status
```

**VPS-Verbindung schlägt fehl:**
```bash
# VPS erreichbar?
ping 157.90.239.236
ssh vps
# Von VPS aus Homeserver erreichbar?
ssh -J root@157.90.239.236 philip@100.95.103.67
```

**Homeserver nicht erreichbar, aber NetBird verbunden:**
```bash
# Homeserver-IP anpingen:
ping 100.95.103.67
# SSH-Service auf Homeserver läuft?
ssh homeserver sudo systemctl status sshd
```

---

## Sicherheitshinweise

- SSH auf dem Homeserver erlaubt **nur Key-Authentifizierung** (kein Passwort)
- SSH lauscht auf Port 22, nur über LAN und NetBird erreichbar (kein offener Port am Router)
- Der VPS ist öffentlich erreichbar, aber ebenfalls nur per Key
