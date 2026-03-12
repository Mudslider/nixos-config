# CLAUDE.md — Projektkontext für Claude Code

## Arbeitsweise

- Verhalte dich wie ein erfahrener Software-Entwickler
- Erkläre kurz was du tust und warum, damit der Nutzer dazulernt (NixOS, Nix-Sprache, Linux, Programmierung)
- Bearbeite Dateien selbstständig und übergib sie zum Testen
- Antizipiere Probleme und Konflikte proaktiv (z.B. fehlende `git add`, Abhängigkeiten zwischen Diensten)
- Immer `nrt` (test) vor `nrs` (switch) — niemals ungetestet switchen
- Gib bei Änderungen an, ob sie Laptop, Server oder beide betreffen

## Architektur

Einheitliches NixOS-Flake-Repo für zwei Maschinen. Dendritisches Pattern mit flake-parts + import-tree.

**Kernprinzipien:**
- Jede Datei in `parts/` ist ein flake-parts Modul (auto-importiert via import-tree)
- Geteilte Config über `nixosModules` mit Typ `deferredModule` (definiert in `parts/module-types.nix`)
- Kein `specialArgs`, keine `default.nix`-Hubs in `parts/`
- `modules/server/` und `modules/desktop/` nutzen intern noch klassische `default.nix`-Hubs

**Referenzen:** [mightyiam/dendritic](https://github.com/mightyiam/dendritic), [flake.parts](https://flake.parts), [YouTube Talk](https://www.youtube.com/watch?v=-TRbzkw6Hjs)

## Maschinen

| | Homeserver | ThinkPad P15 |
|---|---|---|
| Hostname | `homeserver` | `playground` |
| User | `philip` | `polly` |
| Hardware | ASRock N100DC-ITX, 32GB RAM | Intel i9, 32GB RAM, RTX A4000 |
| IP | 192.168.1.10 (LAN), 100.95.103.67 (NetBird) | DHCP |
| Wiring | `parts/homeserver.nix` | `parts/thinkpad-p15.nix` |
| Rebuild | `nrs` = git fetch + reset --hard + nixos-rebuild switch | `nrs` = sudo nixos-rebuild switch |

## Repo-Struktur

```
flake.nix                       ← flake-parts + import-tree
parts/                          ← flake-parts Module (auto-importiert)
  module-types.nix              ← nixosModules Option (deferredModule)
  common/locale.nix             ← → nixosModules.common
  common/nix-settings.nix       ← → nixosModules.common (mergt)
  server.nix                    ← wraps modules/server/ → nixosModules.server
  desktop.nix                   ← wraps modules/desktop/ → nixosModules.desktop
  homeserver.nix                ← Wiring: nixosConfigurations.homeserver
  thinkpad-p15.nix              ← Wiring: nixosConfigurations.thinkpad-p15
hosts/homeserver/               ← User, SSH, hostId, Disko, ZFS-Boot
hosts/thinkpad-p15/             ← User, NVIDIA, Caddy-CA
modules/desktop/                ← KDE, Audio, Peripherie, Pakete
modules/server/
  hardware/                     ← ZFS, Power-Management, HDD-Standby
  networking/                   ← Statische IP, Caddy, NetBird
  security/                     ← SOPS, Firewall, Fail2ban
  services/                     ← Vaultwarden aktiv, Rest auskommentiert in default.nix
  storage/                      ← SSD-Buffer, Restic-Backup, Samba
home/shared/                    ← Geteilte Home-Manager-Config (Git)
home/server/                    ← philip@homeserver
home/laptop/                    ← polly@thinkpad-p15
secrets/secrets.yaml            ← SOPS + age (beide Maschinen)
```

## Aktive Dienste (Server)

| Dienst | Port | Typ |
|--------|------|-----|
| Vaultwarden | 8222 | NixOS-Modul |
| Caddy (Reverse Proxy) | 443 | NixOS-Modul, `tls internal` |
| NetBird (Mesh-VPN) | 51820 | NixOS-Modul, app.netbird.io |
| Restic REST-Server | 8100 | NixOS-Modul, `appendOnly = true` |
| Samba | 445 | NixOS-Modul, nur LAN |
| ZFS Pool `tank` | — | 2× 12TB HDD Mirror, verschlüsselt |

Inaktive Dienste sind vorbereitet in `modules/server/services/` (auskommentiert in `default.nix`).
Zugehörige Caddy-VirtualHosts und Podman-Netzwerke sind ebenfalls auskommentiert.

## Workflow

```bash
# Laptop: editieren → testen → switchen → pushen
cd ~/nixos-config
# Dateien ändern...
nrt                    # IMMER erst testen!
nrs                    # Bei Erfolg switchen
git add -A && git commit -m "..." && git push

# Server: pullen + rebuilden (per SSH oder am Server)
nrs                    # = git fetch + reset --hard origin/main + rebuild
```

**Neuen Dienst aktivieren** (betrifft typisch 4-5 Dateien):
1. `modules/server/services/default.nix` — Import einkommentieren
2. `modules/server/networking/caddy.nix` — VirtualHost einkommentieren
3. `modules/server/security/encryption.nix` — SOPS-Secret hinzufügen (falls nötig)
4. `modules/server/storage/ssd-buffer.nix` — Verzeichnis prüfen (owner erst `root`, nach Aktivierung Service-User)
5. `modules/server/services/podman.nix` — Netzwerk einkommentieren (falls Container mit DB)
6. Testen, switchen, committen, pushen, Server `nrs`

## Kritische Regeln

- **ZFS hostId `687e79ce`** — darf NIEMALS geändert werden, sonst schlägt `zfs-import-tank` fehl
- **`flake.lock`** wird nur vom Laptop committet, nie vom Server ändern lassen
- **SOPS:** `sops updatekeys secrets/secrets.yaml` nach Key-Änderungen, YAML-Keys müssen exakt zu NixOS-Modul-Erwartungen passen
- **tmpfiles owner:** Erst `root root`, Service-User erst setzen wenn der Dienst aktiv ist (sonst `unknown user`)
- **Caddy Root-CA:** Clients brauchen `/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt`

## NixOS-spezifische Eigenheiten

- **Nix-Store ist read-only** — `npm install -g` braucht `prefix ~/.npm-global`, kein `apt install`
- **`sudo` erbt keinen nix-shell PATH** — nutze `sudo nix-shell -p [pkg] --run "[cmd]"`
- **Home Manager verwaltet `.bashrc`** — PATH-Änderungen gehören in `home/laptop/shell.nix` → `initExtra`
- **`scp` scheitert bei Caddy-Verzeichnissen** — nutze `ssh host "sudo cat [file]" > local`
- **`netbird service install` geht nicht auf NixOS** (read-only `/etc/systemd/system/`)
- **Restic REST-Server 0.14.0 braucht bcrypt** — `htpasswd -B` (nicht apr1/MD5, sonst 401)
- **Socket + Service neustarten** nach Credential-Änderungen: `systemctl restart restic-rest-server.socket restic-rest-server`

## NixOS Rescue Shell (`init=/bin/sh`)

Falls Passwort-Reset nötig (getestet auf ThinkPad mit LUKS):
- PATH ist komplett leer, `/run/current-system` existiert nicht
- Niemals `/bin/mount`, `/usr/bin/passwd` oder `/run/current-system/sw/bin/` vorschlagen
- Nix-Store Glob-Loop: `for f in /nix/store/*/bin/COMMAND; do "$f" [args]; break; done`
- Verzeichnisse erkunden: `echo /*` statt `ls`

## Backup-Infrastruktur

- Windows-Arbeitsrechner → Restic REST-Server über NetBird (alle 30 Min, Prune täglich 8 Uhr)
- Ziele: `C:\Users\Philip\Documents` und `E:\`
- Vaultwarden-Daten liegen auf Root-Partition `/var/lib/vaultwarden` (unabhängig von ZFS)
- ZFS-Passphrase nach Reboot: `sudo systemd-tty-ask-password-agent`

## Geplante nächste Schritte

- Nächsten Server-Dienst initialisieren (z.B. Nextcloud)
- Weitere inaktive Dienste bei Bedarf aktivieren
- Systemhärtung (doc 18) am Ende wenn alles läuft
