# nixos-config

Unified NixOS configuration for two machines. One repo, one flake.

## Maschinen

| Name | Hardware | User | Rebuild |
|------|----------|------|---------|
| `homeserver` | ASRock N100DC-ITX, 32GB RAM, NVMe + 2×12TB ZFS Mirror | `philip` | `nrs` (git fetch + reset + rebuild) |
| `thinkpad-p15` | Intel i9, 32GB RAM, NVIDIA RTX A4000 | `polly` | `nrs` (nixos-rebuild switch) |

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
│   └── thinkpad-p15.nix              ← Wiring: baut nixosConfigurations.thinkpad-p15
│
├── hosts/                             ← Maschinenspezifische Config
│   ├── homeserver/                    ← User, SSH, hostId, Disko, ZFS-Boot
│   └── thinkpad-p15/                  ← User, NVIDIA, Netzwerk, Caddy-CA
│
├── modules/                           ← NixOS-Module (intern mit default.nix-Hubs)
│   ├── desktop/                       ← KDE, Audio, Peripherie, Pakete
│   └── server/
│       ├── hardware/                  ← ZFS, Power-Management, HDD-Standby
│       ├── networking/                ← Statische IP, Caddy, NetBird
│       ├── security/                  ← SOPS, Firewall, Fail2ban
│       ├── services/                  ← Vaultwarden (aktiv), Rest vorbereitet
│       └── storage/                   ← SSD-Buffer, Restic-Backup, Samba
│
├── home/                              ← Home-Manager
│   ├── shared/                        ← Geteilte Config (Git)
│   ├── server/                        ← philip@homeserver (Shell, Tools)
│   └── laptop/                        ← polly@thinkpad-p15 (Shell, Tools)
│
├── secrets/
│   └── secrets.yaml                   ← SOPS-verschlüsselt (beide Maschinen)
│
└── docs/                              ← Anleitungen (Obsidian-kompatibel)
```

## Aktive Dienste

| Dienst | Typ | Port | Status |
|--------|-----|------|--------|
| Vaultwarden | NixOS-Modul | 8222 | ✅ aktiv |
| Caddy (Reverse Proxy) | NixOS-Modul | 443 | ✅ aktiv |
| NetBird (Mesh-VPN) | NixOS-Modul | 51820 | ✅ aktiv |
| Restic REST-Server | NixOS-Modul | 8100 | ✅ aktiv |
| Samba | NixOS-Modul | 445 | ✅ aktiv |
| ZFS (Pool `tank`) | Kernel | — | ✅ aktiv |

Weitere Dienste (Nextcloud, Immich, Jellyfin, ...) sind vorbereitet aber auskommentiert in `modules/server/services/default.nix`.

## Anleitungen (docs/)

| Nr. | Thema | Status |
|-----|-------|--------|
| 00 | NixOS-Installation | ✅ erledigt |
| 01 | ZFS-Pool erstellen | ✅ erledigt |
| 02 | Secrets mit SOPS | ✅ erledigt |
| 03 | Netzwerk & Caddy | ✅ erledigt |
| 08 | Vaultwarden | ✅ aktiv |
| 15 | Backup Arbeitsrechner | ✅ aktiv |
| 04–07, 09–14, 16–17 | Weitere Dienste | ⏳ bei Bedarf |
| 18 | Systemhärtung | ⏳ am Ende |
| 19 | ThinkPad-Migration | ✅ abgeschlossen |
| 99 | Neuen Dienst hinzufügen | 📖 Referenz |

## Workflow

```bash
# Laptop: editieren, testen, switchen
cd ~/nixos-config
nano modules/server/services/vaultwarden.nix   # Änderung
nrt                                             # Test-Build
nrs                                             # Switch (bei Erfolg)
git add -A && git commit -m "..." && git push

# Server: pullen + rebuilden
nrs    # = git fetch + git reset --hard origin/main + nixos-rebuild switch
```
