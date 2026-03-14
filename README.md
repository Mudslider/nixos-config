# nixos-config

Unified NixOS configuration for three machines. One repo, one flake.

## Maschinen

| Name | Hardware | User | IP | Rebuild |
|------|----------|------|----|---------|
| `homeserver` | ASRock N100DC-ITX, 32GB RAM, NVMe + 2×12TB ZFS Mirror | `philip` | 192.168.178.10 (LAN), 100.95.103.67 (NetBird) | `nrs` (git fetch + reset + rebuild) |
| `thinkpad-p15` | Intel i9, 32GB RAM, NVIDIA RTX A4000 | `polly` | DHCP | `nrs` (nixos-rebuild switch) |
| `vps` | Hetzner CX23, Nürnberg | `root` | 157.90.239.236 | `nixos-rebuild switch --flake .#vps --target-host root@157.90.239.236 --build-host localhost` |

## Architektur

Das Repo nutzt das **dendritische Pattern** mit flake-parts + import-tree:
- Jede Datei in `parts/` ist ein flake-parts Modul (auto-importiert)
- Geteilte Config wird über `nixosModules` mit Typ `deferredModule` zusammengeführt
- Kein `specialArgs`, keine `default.nix`-Hubs in `parts/`

## Struktur

```
nixos-config/
├── flake.nix                          ← Einstiegspunkt (flake-parts + import-tree)
│
├── parts/                             ← flake-parts Module (auto-importiert)
│   ├── module-types.nix               ← nixosModules Option (deferredModule)
│   ├── common/
│   │   ├── locale.nix                 ← Lokalisierung (→ nixosModules.common)
│   │   └── nix-settings.nix           ← Nix/Flake-Settings (→ nixosModules.common)
│   ├── server.nix                     ← Wraps modules/server/ (→ nixosModules.server)
│   ├── desktop.nix                    ← Wraps modules/desktop/ (→ nixosModules.desktop)
│   ├── homeserver.nix                 ← Wiring: baut nixosConfigurations.homeserver
│   ├── thinkpad-p15.nix               ← Wiring: baut nixosConfigurations.thinkpad-p15
│   └── vps.nix                        ← Wiring: baut nixosConfigurations.vps
│
├── hosts/                             ← Maschinenspezifische Config
│   ├── homeserver/                    ← User, SSH, hostId, Disko, ZFS-Boot
│   ├── thinkpad-p15/                  ← User, NVIDIA, Netzwerk, Caddy-CA
│   └── vps/                           ← Caddy (Let's Encrypt), Firewall, Fail2ban
│
├── modules/                           ← NixOS-Module (intern mit default.nix-Hubs)
│   ├── desktop/                       ← KDE, Audio, Peripherie, Pakete
│   └── server/
│       ├── hardware/                  ← ZFS, Power-Management, HDD-Standby
│       ├── networking/                ← Statische IP, Caddy, NetBird
│       ├── security/                  ← SOPS, Firewall, Fail2ban
│       ├── services/                  ← Aktive Dienste (Container + NixOS-Module)
│       └── storage/                   ← SSD-Buffer, Restic-Backup, Samba
│
├── home/                              ← Home-Manager
│   ├── shared/                        ← Geteilte Config (Git)
│   ├── server/                        ← philip@homeserver (Shell, Tools)
│   └── laptop/                        ← polly@thinkpad-p15 (Shell, Tools)
│
├── secrets/
│   └── secrets.yaml                   ← SOPS-verschlüsselt (alle drei Maschinen)
│
└── docs/                              ← Anleitungen (Obsidian-kompatibel)
```

## Aktive Dienste (Homeserver)

| Dienst | Typ | Port | Öffentlich |
|--------|-----|------|------------|
| Vaultwarden | NixOS-Modul | 8222 | `vaultwarden.philipjonasch.de` |
| Caddy (Reverse Proxy) | NixOS-Modul | 443 | intern + VPS-Weiterleitung |
| NetBird (Mesh-VPN) | NixOS-Modul | 51820 | P2P zu VPS + Clients |
| Restic REST-Server | NixOS-Modul | 8100 (NetBird only) | — |
| Samba | NixOS-Modul | 445 | — |
| ZFS Pool `tank` | Kernel | — | 2× 12TB HDD Mirror |
| Paperless-NGX | Podman | 8000 | `paperless.philipjonasch.de` |
| Nextcloud | NixOS-Modul | 8080 | `nextcloud.philipjonasch.de` |
| Immich | Podman | 2283 | `immich.philipjonasch.de` |
| Backrest (Restic UI) | systemd | 9898 | `backrest.home.lan` |
| Uptime Kuma | Podman | 3001 | `uptime-kuma.home.lan` |
| Grafana | NixOS-Modul | 3000 | `grafana.home.lan` |

Weitere Dienste (Jellyfin, Home Assistant, ...) vorbereitet aber inaktiv in `modules/server/services/default.nix`.

## VPS (Hetzner CX23, 157.90.239.236)

Öffentlicher Reverse Proxy mit Let's Encrypt TLS. Leitet Traffic via NetBird-Tunnel (WireGuard) zum Homeserver weiter. Eigene Dienste: Caddy, NetBird, Fail2ban.

## Workflow

```bash
# Laptop: editieren, testen, switchen
cd ~/nixos-config
nrt                                             # IMMER erst testen!
nrs                                             # Switch (bei Erfolg)
git add -A && git commit -m "..." && git push

# Server: pullen + rebuilden
nrs    # = git fetch + git reset --hard origin/main + nixos-rebuild switch

# VPS: vom Laptop aus deployen
nixos-rebuild switch --flake .#vps --target-host root@157.90.239.236 --build-host localhost
```
