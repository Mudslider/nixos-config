# 19 — ThinkPad P15 ins vereinte Repo migrieren

Diese Anleitung beschreibt, wie du deine bestehende ThinkPad-Config aus dem
alten Repo (`~/nixos-config` auf dem Laptop, GitHub: Mudslider/nixos-config)
in das neue vereinte Repo überführst.

---

## Übersicht: Was wohin kommt

| Altes Repo (Laptop) | Neues Repo | Bemerkung |
|---------------------|-----------|-----------|
| `flake.nix` | `flake.nix` (schon drin) | Bereits vorbereitet mit `thinkpad-p15` |
| `hosts/*/hardware-configuration.nix` | `hosts/thinkpad-p15/hardware-configuration.nix` | 1:1 kopieren |
| `modules/hardware/nvidia.nix` | `hosts/thinkpad-p15/` oder `modules/desktop/` | NVIDIA ist laptop-spezifisch |
| `modules/desktop/plasma.nix` | `modules/desktop/plasma.nix` | Könnte theoretisch geteilt werden |
| `modules/programs/packages.nix` | `hosts/thinkpad-p15/` oder `modules/desktop/` | Desktop-Pakete |
| `modules/locale/` | `modules/common/locale.nix` | Bereits im neuen Repo (geteilt) |
| `modules/core/nix-settings.nix` | `modules/common/nix-settings.nix` | Bereits im neuen Repo (geteilt) |
| `modules/services/pipewire.nix` | `modules/desktop/audio.nix` | Nur Desktop braucht Audio |
| `modules/security/encryption.nix` | Eigene Datei oder weglassen | Falls Laptop auch SOPS nutzt |
| `home/` (Home-Manager) | `home/laptop/` | Laptop-spezifische HM-Config |
| `.sops.yaml` | `.sops.yaml` (schon drin) | Laptop-Key ist bereits vorgesehen |

---

## Schritt 1: Altes Repo sichern

Auf dem **Laptop**:

```bash
# Altes Repo umbenennen (nicht löschen!)
mv ~/nixos-config ~/nixos-config-alt

# Neues vereintes Repo klonen
git clone git@github.com:Mudslider/nixos-config.git ~/nixos-config
```

Falls das neue Repo noch nicht auf GitHub ist, kopiere es stattdessen vom Server:

```bash
scp -r philip@192.168.1.10:~/nixos-config ~/nixos-config
```

## Schritt 2: hardware-configuration.nix kopieren

```bash
cp ~/nixos-config-alt/hosts/*/hardware-configuration.nix \
   ~/nixos-config/hosts/thinkpad-p15/hardware-configuration.nix
```

Falls die Datei woanders liegt:

```bash
# Suchen:
find ~/nixos-config-alt -name "hardware-configuration.nix"
# Dann entsprechend kopieren
```

## Schritt 3: Maschinenspezifische Config aufbauen

Editiere `hosts/thinkpad-p15/default.nix` — ersetze den Platzhalter mit deiner
echten Config. Die Grundstruktur:

```bash
nano ~/nixos-config/hosts/thinkpad-p15/default.nix
```

Übernimm aus deiner alten Config:
- `networking.hostName`
- Bootloader-Einstellungen
- User `polly` (mit `extraGroups`, `initialPassword`, SSH-Key)
- NVIDIA-Konfiguration (falls in einem eigenen Modul: nach `modules/desktop/` verschieben)

**Beispiel-Struktur:**

```nix
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "playground";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Benutzer ──────────────────────────────────────────────
  users.users.polly = {
    isNormalUser = true;
    description = "Polly";
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "changeme";
    shell = pkgs.bash;
  };

  # ── NVIDIA (aus altem nvidia.nix übernehmen) ──────────────
  # hardware.nvidia = { ... };
  # hardware.nvidia.prime = { ... };

  # ── Desktop ───────────────────────────────────────────────
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.xserver.xkb.layout = "de";

  # ── Audio ─────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ── Pakete ────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    firefox
    thunderbird
    libreoffice-qt
    obsidian
    bitwarden-desktop
    darktable
    gimp
    vlc
    audacity
    chromium
    sops
    age
    git
    wget
    curl
    htop
  ];

  # ── Netzwerk ──────────────────────────────────────────────
  networking.networkmanager.enable = true;

  # ── Printing ──────────────────────────────────────────────
  services.printing.enable = true;

  system.stateVersion = "24.11";
}
```

> **Tipp:** Fang mit einer großen `default.nix` an, die alles enthält.
> Aufteilen in einzelne Module (desktop/, nvidia.nix, etc.) kannst du später.

## Schritt 4: Home-Manager (optional)

Falls dein altes Repo Home-Manager nutzt, kopiere die Dateien:

```bash
cp ~/nixos-config-alt/home/*.nix ~/nixos-config/home/laptop/
```

Passe `home/laptop/default.nix` an:

```nix
{ pkgs, ... }:
{
  imports = [
    # Dateien die du kopiert hast
  ];

  home = {
    username = "polly";
    homeDirectory = "/home/polly";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
```

Dann in `flake.nix` den Home-Manager-Block für `thinkpad-p15` einkommentieren.

## Schritt 5: Module auslagern (optional, später)

Wenn die `default.nix` zu groß wird, kannst du Teile in `modules/desktop/` auslagern:

```
modules/desktop/
├── default.nix       ← imports alles
├── plasma.nix        ← KDE Plasma 6
├── nvidia.nix        ← NVIDIA PRIME Offload
├── audio.nix         ← PipeWire
└── packages.nix      ← Desktop-Pakete
```

Dann im Laptop-Host:

```nix
imports = [
  ./hardware-configuration.nix
  ../../modules/desktop      # ← Desktop-Module importieren
];
```

Und in `flake.nix` optional `./modules/desktop` zur Modulliste hinzufügen.

## Schritt 6: Testen

```bash
cd ~/nixos-config
sudo nixos-rebuild test --flake ~/nixos-config#thinkpad-p15
```

`test` statt `switch` — so wird die Config getestet ohne sie permanent zu aktivieren.
Falls alles funktioniert:

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-p15
```

## Schritt 7: Committen

```bash
cd ~/nixos-config
git add -A
git commit -m "ThinkPad P15 Config migriert"
git push
```

## Schritt 8: Altes Repo aufräumen

Wenn alles funktioniert:

```bash
# Auf GitHub: Altes Repo archivieren oder löschen
# Lokal:
rm -rf ~/nixos-config-alt  # Erst wenn du sicher bist!
```

---

## Fehlerbehebung

### "attribute 'thinkpad-p15' not found"

Der Name in `flake.nix` unter `nixosConfigurations` muss exakt mit dem
`#`-Namen im Rebuild-Befehl übereinstimmen.

### NVIDIA-Probleme nach Migration

Prüfe, dass `nixpkgs.config.allowUnfree = true;` gesetzt ist (in `modules/common/nix-settings.nix` — ist es bereits).

### Home-Manager Konflikte

Falls Home-Manager-Optionen zwischen altem und neuem Repo kollidieren,
prüfe ob die `stateVersion` in `home/laptop/default.nix` stimmt.

### "collision between ... and ..."

Zwei Module definieren die gleiche Option. Typisch wenn Locale sowohl in
`modules/common/locale.nix` als auch im alten Host-Config definiert ist.
Entferne die doppelte Definition aus dem Host-Config.

---

## Zusammenfassung Workflow

Ab jetzt gilt für **beide** Maschinen:

```bash
# Auf dem Server:
cd ~/nixos-config
git pull
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver

# Auf dem Laptop:
cd ~/nixos-config
git pull
sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-p15
```

Änderungen von einer Maschine sind sofort auf der anderen verfügbar per `git pull`.
