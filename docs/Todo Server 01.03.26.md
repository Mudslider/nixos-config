# Todo Server — Neustart 01.03.26

## Repos zusammengeführt

- Altes Setup: Laptop (`~/nixos-config`) + Server (`~/nixos-homeserver-config`) = 2 Repos
- Neues Setup: Ein Repo (`~/nixos-config`) mit `flake.nix` die beide Maschinen definiert
- Vorteil: SOPS-Secrets nur noch an einer Stelle, kein manuelles Kopieren mehr

## Reihenfolge

1. **doc 00** — NixOS installieren (USB-Stick, Disko, erster Boot)
2. **doc 01** — ZFS-Pool erstellen (Mirror, Encryption, Datasets)
3. **doc 02** — SOPS-Secrets einrichten (ein Repo, beide Keys)
4. **doc 03** — Netzwerk + Caddy (vorerst LAN-only, kein NetBird)
5. **doc 08** — Vaultwarden (Passwort-Manager zuerst!)
6. **doc 04** — Nextcloud
7. **doc 05** — Immich
8. **doc 06** — Paperless
9. **doc 07** — Jellyfin
10. **doc 09** — Forgejo
11. Rest nach Bedarf
12. **doc 18** — Systemhärtung (ganz am Ende!)

## Änderungen gegenüber alter Config

- `modules/core/` → aufgeteilt in `modules/common/` (geteilt) + `hosts/homeserver/` (maschinenspezifisch)
- `modules/networking/` → `modules/server/networking/`
- `modules/services/` → `modules/server/services/`
- `modules/storage/` → `modules/server/storage/`
- `modules/hardware/` → `modules/server/hardware/`
- `modules/security/` → `modules/server/security/`
- `home/` → `home/server/` (Laptop: `home/laptop/`)
- SSH: Passwort-Auth in der Installationsphase aktiviert (Rettungsanker)
- User: `initialPassword = "server"` statt kein Passwort
- User: `users.groups.philip = {};` explizit definiert
- Firewall: Kein NetBird/wt0, nur LAN
- Rebuild-Befehl: `--flake ~/nixos-config#homeserver`

## Noch zu migrieren

- [ ] ThinkPad P15 Config von altem `~/nixos-config` Repo → `hosts/thinkpad-p15/`
- [ ] Desktop-Module (KDE, NVIDIA, Audio) → `modules/desktop/`
- [ ] Home-Manager für Laptop → `home/laptop/`
