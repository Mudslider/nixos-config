# nixos-config

Unified NixOS configuration for all machines. One repo, one flake, multiple systems.

## Maschinen

| Name | Hardware | Rebuild-Befehl |
|------|----------|----------------|
| `homeserver` | ASRock N100DC-ITX, 32GB RAM, NVMe + 2×12TB ZFS Mirror | `sudo nixos-rebuild switch --flake ~/nixos-config#homeserver` |
| `thinkpad-p15` | Intel i9, 32GB RAM, RTX A4000 | `sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-p15` |

## Struktur

```
nixos-config/
├── flake.nix                  ← Einstiegspunkt (definiert beide Maschinen)
├── hosts/
│   ├── homeserver/            ← Server: Users, SSH, Hardware, Disko
│   └── thinkpad-p15/          ← Laptop: Users, Desktop, NVIDIA
├── modules/
│   ├── common/                ← Geteilt: Locale, Nix-Settings
│   ├── server/                ← Nur Server: ZFS, Dienste, Firewall
│   │   ├── hardware/          … ZFS, Power, HDD-Standby
│   │   ├── networking/        … Statische IP, Caddy, (NetBird)
│   │   ├── security/          … SOPS, Firewall, Fail2ban
│   │   ├── services/          … Nextcloud, Vaultwarden, Jellyfin, ...
│   │   └── storage/           … SSD-Buffer, Backup, Offsite
│   └── desktop/               ← Nur Laptop: Plasma, NVIDIA, Audio
├── home/
│   ├── server/                ← Home-Manager: philip@homeserver
│   └── laptop/                ← Home-Manager: polly@thinkpad-p15
├── secrets/
│   └── secrets.yaml           ← Verschlüsselt (SOPS) — beide Maschinen
└── docs/                      ← Anleitungen (Obsidian-kompatibel)
```

## Anleitungen (docs/)

Empfohlene Reihenfolge für den Homeserver:

1. `00` — NixOS-Installation
2. `01` — ZFS-Pool erstellen
3. `02` — Secrets mit SOPS einrichten
4. `03` — Netzwerk & Caddy
5. `08` → `04` → `05` → Rest — Dienste aktivieren
6. `18` — Systemhärtung (am Ende)

## Passwort-Strategie

Während der Installation: einfache Passwörter, kein Lockout-Risiko.
Nach Abschluss: Härtungsphase (doc 18) mit sicheren Passwörtern.

Details: siehe `docs/00-installation-betriebssystem.md`
