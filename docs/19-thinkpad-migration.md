# 19 — ThinkPad P15 ins vereinte Repo migrieren

> **✅ ABGESCHLOSSEN** (März 2026) — ThinkPad ist vollständig ins vereinte Repo migriert.
> Dieses Dokument dient als Referenz falls eine weitere Maschine hinzugefügt wird.

---

## Ergebnis der Migration

| Komponente | Ort im Repo |
|-----------|-------------|
| Hardware-Config | `hosts/thinkpad-p15/hardware-configuration.nix` |
| Maschinenspezifisch | `hosts/thinkpad-p15/default.nix` (NVIDIA, User, Netzwerk) |
| Desktop-Module | `modules/desktop/` (KDE, Audio, Peripherie, Pakete) |
| Home-Manager | `home/laptop/` (User `polly`, Shell, Tools) |
| Caddy Root CA | `hosts/thinkpad-p15/caddy-root-ca.crt` |
| Wiring | `parts/thinkpad-p15.nix` (flake-parts) |

## Workflow

```bash
# Auf dem Laptop:
cd ~/nixos-config
# Editieren → testen → switchen:
nrs    # Alias für: sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-p15
# Commit + Push, dann auf Server:
nrs    # Alias für: git fetch + reset --hard + nixos-rebuild switch
```

## Neue Maschine hinzufügen (Kurzanleitung)

1. `hosts/neue-maschine/` mit `default.nix` + `hardware-configuration.nix`
2. `parts/neue-maschine.nix` als Wiring-Modul (nach Muster von `thinkpad-p15.nix`)
3. `home/neue-maschine/` für Home-Manager
4. Optional: eigenes `nixosModules.XXX` in `parts/` falls geteilte Module nötig
5. `git add`, rebuild mit `--flake .#neue-maschine`
