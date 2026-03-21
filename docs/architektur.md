# 🏗️ Architektur-Übersicht: nixos-config

> Einheitliches NixOS-Flake-Repo für drei Maschinen.
> Dendritisches Pattern mit **flake-parts** + **import-tree**.

---

## 🖥️ Maschinen

| | 🏠 Homeserver | 💻 ThinkPad P15 | ☁️ VPS |
|---|---|---|---|
| **Hostname** | `homeserver` | `playground` | `vps` |
| **Flake-Config** | `nixosConfigurations.homeserver` | `nixosConfigurations.thinkpad-p15` | `nixosConfigurations.vps` |
| **User** | `philip` | `polly` | `root` |
| **Hardware** | ASRock N100DC-ITX, 32 GB RAM | Intel i9, 32 GB RAM, RTX A4000 | Hetzner CX23 |
| **IP** | 192.168.178.10 (LAN) · 100.95.103.67 (NetBird) | DHCP | 157.90.239.236 (public) |
| **Wiring** | `parts/homeserver.nix` | `parts/thinkpad-p15.nix` | `parts/vps.nix` |
| **Rebuild** | `nixos-rebuild switch` via SSH vom Laptop | `nrt && nrs` lokal | `nixos-rebuild switch` via SSH vom Laptop |

---

## 📐 Schichtenmodell

```
flake.nix
└── parts/                        ← auto-importiert via import-tree
    ├── common/                   ← nixosModules.common  (beide Maschinen)
    ├── server.nix                ← nixosModules.server  (nur Homeserver)
    ├── desktop.nix               ← nixosModules.desktop (nur Laptop)
    ├── homeserver.nix            ← Wiring: Common + Server + hosts/homeserver + Home-Manager
    ├── thinkpad-p15.nix          ← Wiring: Common + Desktop + hosts/thinkpad-p15 + Home-Manager
    └── vps.nix                   ← Wiring: Common + hosts/vps + disko + sops
```

---

## 🗂️ Entscheidungstabelle: Was gehört wohin?

### ⚙️ Flake-Orchestrierung (`parts/`)

| Datei | Maschine | Zweck |
|-------|----------|-------|
| `flake.nix` | alle | Eingangspunkt, inputs, auto-import |
| `parts/module-types.nix` | alle | Definiert `nixosModules`-Option als `deferredModule` |
| `parts/common/locale.nix` | alle | Zeitzone, Keyboard, Sprache |
| `parts/common/nix-settings.nix` | alle | GC, Flakes, `allowUnfree` |
| `parts/server.nix` | Homeserver | Wraps `modules/server/` → `nixosModules.server` |
| `parts/desktop.nix` | Laptop | Wraps `modules/desktop/` → `nixosModules.desktop` |
| `parts/homeserver.nix` | Homeserver | Common + Server + hosts/homeserver + Home-Manager |
| `parts/thinkpad-p15.nix` | Laptop | Common + Desktop + hosts/thinkpad-p15 + Home-Manager |
| `parts/vps.nix` | VPS | Common + hosts/vps + disko + sops |

---

### 🖥️ Maschinenspezifisch (`hosts/`)

> Hardware, Boot-Loader, Benutzer, SSH-Keys — alles was pro Maschine einmalig ist.

| Datei | Maschine | Zweck |
|-------|----------|-------|
| `hosts/homeserver/default.nix` | Homeserver | hostId `687e79ce` ⚠️, philip, GRUB, ZFS-Boot |
| `hosts/homeserver/disko-config.nix` | Homeserver | ZFS-Datasets, SSD-Partitionen |
| `hosts/thinkpad-p15/default.nix` | Laptop | polly, NVIDIA Offload, NetworkManager |
| `hosts/thinkpad-p15/backup.nix` | Laptop | Restic-Backup → Homeserver (taeglich) |
| `hosts/vps/default.nix` | VPS | philip, GRUB, Key-Auth, SOPS age-Key |
| `hosts/vps/disk.nix` | VPS | GPT + EF02-Partition + ext4 |
| `hosts/vps/caddy.nix` | VPS | Let's Encrypt, `*.philipjonasch.de` |
| `hosts/vps/netbird.nix` | VPS | Setup-Key aus SOPS, Port 51820 |
| `hosts/vps/firewall.nix` | VPS | Port 2222, 80, 443 |
| `hosts/vps/fail2ban.nix` | VPS | SSH-Brute-Force-Schutz |

---

### 🛠️ Server-Module (`modules/server/`)

> NixOS-Konfiguration für den Homeserver — aufgeteilt nach Verantwortlichkeit.

#### Hardware
| Datei | Zweck |
|-------|-------|
| `hardware/` | ZFS-Pool `tank`, ASPM-Power-Management, HDD-Standby |

#### Networking
| Datei | Zweck |
|-------|-------|
| `networking/static-ip.nix` | IP 192.168.178.10, Gateway, DNS |
| `networking/caddy.nix` | Reverse Proxy: `home.lan` + `philipjonasch.de` HTTP-Routen |
| `networking/netbird.nix` | Mesh-VPN, NetBird-IP 100.95.103.67 |
| `networking/dns.nix` | dnsmasq: `*.home.lan → 192.168.178.10` |

#### Security
| Datei | Zweck |
|-------|-------|
| `security/encryption.nix` | SOPS-Secrets deklarieren (welche entschlüsselt werden) |
| `security/firewall.nix` | Erlaubte Ports, LAN-Ranges |
| `security/fail2ban.nix` | SSH-Brute-Force-Schutz |

#### Services
| Datei | Zweck |
|-------|-------|
| `services/default.nix` | ⭐ Import-Hub — hier Dienste ein-/auskommentieren |
| `services/podman.nix` | Container-Runtime + Netzwerke (immich-net, paperless-net) |
| `services/vaultwarden.nix` | Passwort-Manager, Port 8222 |
| `services/nextcloud.nix` | Nextcloud 33, nginx intern Port 8080 |
| `services/immich.nix` | Foto-Verwaltung, Port 2283, `/tank/photos` |
| `services/paperless-ngx.nix` | Dokument-Verwaltung, Port 8000 |
| `services/ntfy.nix` | Push-Benachrichtigungen, Port 8084 |
| `services/uptime-kuma.nix` | Uptime-Monitoring, Port 3001 |
| `services/monitoring.nix` | Grafana, Port 3100 |
| *(auskommentiert)* | jellyfin, audiobookshelf, navidrome, forgejo, home-assistant, syncthing, authentik, rustdesk |

#### Storage
| Datei | Zweck |
|-------|-------|
| `storage/ssd-buffer.nix` | Verzeichnisse anlegen: `/srv/ssd-buffer/`, `/tank/media/` |
| `storage/backup.nix` | Restic REST-Server, Port 8100 (0.0.0.0), htpasswd, `appendOnly` |
| `storage/nightly-sync.nix` | Tiering SSD→HDD (3 Uhr), Fotos, Paperless, Backup-Repos |

---

### 🖼️ Desktop-Module (`modules/desktop/`)

> NixOS-Konfiguration für den Laptop.

| Datei | Zweck |
|-------|-------|
| `desktop/kde.nix` | KDE Plasma, Wayland/X11, Display-Manager |
| `desktop/audio.nix` | PipeWire |
| `desktop/peripherals.nix` | Drucker (CUPS), Scanner, USB-Geräte |
| `desktop/packages.nix` | **GUI-Apps** (Firefox, Thunderbird, Signal, LibreOffice, Darktable, Nextcloud-Client) |

> 💡 **Regel:** Hat die App ein Fenster? → `packages.nix`

---

### 🏠 Home-Manager (`home/`)

> Benutzer-spezifische Konfiguration — läuft ohne Root-Rechte.

| Datei | Benutzer | Zweck |
|-------|----------|-------|
| `home/shared/git.nix` | alle | Git: Name, E-Mail, Aliase |
| `home/laptop/tools.nix` | polly | **CLI-Tools:** curl, jq, sops, age, netbird, nodejs |
| `home/laptop/shell.nix` | polly | Aliases (`nrs`, `nrt`, `nfu`), npm-global PATH |
| `home/server/tools.nix` | philip | **CLI-Tools:** restic, iftop, tcpdump, powertop |
| `home/server/shell.nix` | philip | `nrs` = git fetch + reset --hard + rebuild |

> 💡 **Regel:** CLI-Tool ohne Fenster? → `home/{laptop|server}/tools.nix`

---

### 🔐 Secrets (`secrets/`)

| Datei | Zweck |
|-------|-------|
| `secrets/secrets.yaml` | SOPS-verschlüsselt, für alle 3 Maschinen |
| `.sops.yaml` | age-Keys: Homeserver + Laptop + VPS |

**Aktive Secrets:**

| Key | Verwendet von |
|-----|---------------|
| `vaultwarden-env` | Homeserver: Vaultwarden |
| `nextcloud-admin-pass` | Homeserver: Nextcloud |
| `netbird-setup-key` | Homeserver + VPS: NetBird |
| `immich-db-password` | Homeserver: Immich PostgreSQL |
| `restic-password-windows` | Backup: Praxis_NUC |
| `restic-password-polly` | Backup: ThinkPad P15 |
| `restic-password-nora` | Backup: Noras Laptop |
| `restic-password-berlin` | Backup: Bruder (inaktiv) |
| *(deaktiviert)* | offsite-backup-password, restic-repo-password |

---

## 🔄 Traffic-Fluss (öffentlich)

```
Internet
  └── *.philipjonasch.de (DNS → 157.90.239.236)
        └── VPS Caddy (HTTPS/443, Let's Encrypt)
              └── NetBird-Tunnel (WireGuard, ~19ms)
                    └── Homeserver Caddy (HTTP/80)
                          ├── vaultwarden.philipjonasch.de → localhost:8222
                          ├── immich.philipjonasch.de      → localhost:2283
                          ├── paperless.philipjonasch.de   → localhost:8000
                          └── nextcloud.philipjonasch.de   → localhost:8080 (nginx)
```

## 🏠 Traffic-Fluss (lokal)

```
Heimnetz
  └── *.home.lan (DNS → 192.168.178.10 via dnsmasq)
        └── Homeserver Caddy (HTTPS/443, interne CA)
              ├── vaultwarden.home.lan  → localhost:8222
              ├── immich.home.lan       → localhost:2283
              ├── paperless.home.lan    → localhost:8000
              ├── nextcloud.home.lan    → localhost:8080 (nginx)
              ├── ntfy.home.lan         → localhost:8084
              ├── status.home.lan      → localhost:3001 (Uptime Kuma)
              ├── backrest.home.lan    → localhost:9898
              └── grafana.home.lan     → localhost:3100
```

---

## ⚠️ Kritische Regeln

| Regel | Grund |
|-------|-------|
| ZFS hostId `687e79ce` **niemals ändern** | `zfs-import-tank` schlägt sonst fehl |
| `flake.lock` nur vom Laptop committen | Server darf nie `nfu` ausführen |
| Immer `nrt` vor `nrs` | Niemals ungetestet switchen |
| `tmpfiles` owner erst setzen wenn Dienst aktiv | Sonst: `unknown user`-Fehler |
| `sops updatekeys` nach Key-Änderungen | Sonst können neue Maschinen nicht entschlüsseln |
