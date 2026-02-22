# NixOS – ThinkPad P15 (Dendritic Pattern)

## Übersicht

Diese Konfiguration richtet NixOS auf einem **Lenovo ThinkPad P15** ein:

| Komponente | Wert |
|---|---|
| CPU | Intel Core i9 |
| RAM | 32 GB DDR4 |
| GPU | NVIDIA RTX A4000 (8 GB VRAM) |
| Desktop | KDE Plasma 6 (Wayland) |
| Sprache | Deutsch |
| Zeitzone | Europe/Berlin |
| NixOS-Channel | unstable (Flake) |

---

## Was ist das Dendritic Pattern?

Das **Dendritic Pattern** (von [mightyiam/dendritic](https://github.com/mightyiam/dendritic)) organisiert eine NixOS-Konfiguration als **Baumstruktur** (dendritisch = baumartig). Jedes Blatt (Leaf) konfiguriert genau **eine** Sache. Jeder Ast (Branch) gruppiert verwandte Blätter über eine `default.nix`, die alle Kinder importiert.

**Vorteile:**
- Jede Datei hat genau eine Verantwortung → leicht zu finden und zu ändern.
- Neue Module hinzufügen = neue Datei + Import in `default.nix`.
- Übersichtlich auch bei wachsender Komplexität.

### Verzeichnisbaum

```
nixos-config/
│
├── flake.nix                  ← Einstiegspunkt (Flake)
├── flake.lock                 ← (wird automatisch erzeugt)
├── hardware-configuration.nix ← Hardware-Scan (maschinenspezifisch)
├── .sops.yaml                 ← SOPS-Konfiguration
├── secrets/
│   └── secrets.yaml           ← Verschlüsselte Secrets
│
└── modules/                   ← Dendritic-Wurzel
    ├── default.nix            ← importiert alle Äste
    │
    ├── hardware/              ── Hardware-Ast
    │   ├── default.nix
    │   ├── cpu.nix            … Intel Microcode & Thermald
    │   ├── nvidia.nix         … RTX A4000 Treiber (PRIME Offload)
    │   ├── bluetooth.nix      … Bluetooth
    │   └── firmware.nix       … Firmware & fwupd
    │
    ├── desktop/               ── Desktop-Ast
    │   ├── default.nix
    │   ├── plasma.nix         … KDE Plasma 6 + SDDM
    │   ├── fonts.nix          … Schriftarten
    │   └── xdg.nix            … XDG-Portale
    │
    ├── networking/            ── Netzwerk-Ast
    │   ├── default.nix
    │   ├── networkmanager.nix … NetworkManager
    │   └── firewall.nix       … Firewall (aktiviert)
    │
    ├── locale/                ── Lokalisierung-Ast
    │   ├── default.nix
    │   ├── timezone.nix       … Europe/Berlin
    │   ├── language.nix       … de_DE.UTF-8
    │   └── keyboard.nix       … Deutsches Tastaturlayout
    │
    ├── programs/              ── Programme-Ast
    │   ├── default.nix
    │   ├── firefox.nix        … Firefox + uBlock Origin + Privacy Badger
    │   ├── chromium.nix       … Chromium
    │   ├── neovim.nix         … Neovim (als $EDITOR)
    │   └── packages.nix       … Thunderbird, LibreOffice, GIMP, etc.
    │
    ├── services/              ── Dienste-Ast
    │   ├── default.nix
    │   ├── pipewire.nix       … Audio (PipeWire)
    │   ├── printing.nix       … Drucken (CUPS)
    │   ├── vaultwarden.nix    … Passwort-Manager (lokal)
    │   └── openssh.nix        … SSH-Server
    │
    ├── security/              ── Sicherheits-Ast
    │   ├── default.nix
    │   └── sops.nix           … sops-nix Secrets-Management
    │
    ├── system/                ── System-Ast
    │   ├── default.nix
    │   ├── bootloader.nix     … systemd-boot (UEFI)
    │   └── nix-settings.nix   … Flakes, GC, Store-Optimierung
    │
    └── users/                 ── Benutzer-Ast
        ├── default.nix
        └── hauptnutzer.nix    … Hauptbenutzer-Konto
```

### Visualisierung: Datenfluss

```
┌─────────────────────────────────────────────────────────────┐
│                        flake.nix                            │
│  inputs: nixpkgs (unstable), sops-nix                       │
│  outputs: nixosConfigurations.thinkpad-p15                  │
└──────────────────────────┬──────────────────────────────────┘
                           │
              ┌────────────┼────────────────┐
              │            │                │
              ▼            ▼                ▼
     hardware-       modules/          sops-nix
     configuration   default.nix       .nixosModules
     .nix            (Dendrit-         .sops
     (auto-gen.)      Wurzel)
                       │
       ┌───────┬───────┼───────┬────────┬────────┐
       │       │       │       │        │        │
       ▼       ▼       ▼       ▼        ▼        ▼
    hardware desktop network locale  programs services ...
       │       │       │       │        │        │
       ▼       ▼       ▼       ▼        ▼        ▼
    cpu.nix  plasma  fire-   time-   firefox  pipe-
    nvidia   fonts   wall    zone    nvim     wire
    blue-    xdg     net-    lang    chrom.   vault-
    tooth            mgr     keyb.   pkgs     warden
    firm-                                     cups
    ware                                      ssh
```

### Visualisierung: NVIDIA PRIME Offload

```
┌─────────────────────────────────────────────────┐
│            ThinkPad P15 GPU-Setup                │
│                                                  │
│  ┌──────────────┐       ┌──────────────────┐    │
│  │  Intel iGPU  │       │  NVIDIA RTX A4000│    │
│  │  (PCI:0:2:0) │       │  (PCI:1:0:0)     │    │
│  │              │       │  8 GB VRAM        │    │
│  │  ● Display   │       │                   │    │
│  │  ● 2D-Apps   │       │  ● 3D / CUDA     │    │
│  │  ● Desktop   │       │  ● GPU-Computing  │    │
│  └──────┬───────┘       └────────┬──────────┘    │
│         │                        │               │
│         │   ┌────────────────┐   │               │
│         └──►│  PRIME Offload │◄──┘               │
│             │                │                   │
│             │  nvidia-offload│                   │
│             │  <command>     │                   │
│             └────────────────┘                   │
└─────────────────────────────────────────────────┘
```

---

## Was wurde konfiguriert?

### 1. Flakes
Flakes sind über `nix-settings.nix` aktiviert (`experimental-features = ["nix-command" "flakes"]`). Die gesamte Konfiguration ist als Flake aufgebaut (`flake.nix`), was reproduzierbare Builds und einfache Updates ermöglicht.

### 2. NVIDIA-Treiber
In `hardware/nvidia.nix`:
- **Proprietärer Treiber** (stable) für die RTX A4000.
- **PRIME Offload**: Die Intel-iGPU bedient das Display. Die NVIDIA-GPU steht on-demand bereit. Um eine Anwendung auf der NVIDIA-GPU zu starten: `nvidia-offload <befehl>`.
- **Modesetting** aktiviert (notwendig für Wayland/KWin).
- **OpenGL & Vulkan** inkl. 32-Bit-Unterstützung.

### 3. KDE Plasma 6
In `desktop/plasma.nix`:
- SDDM als Display-Manager (Wayland-Modus).
- Plasma 6 Desktop-Umgebung.
- XDG-Portale für Screen-Sharing und Datei-Dialoge.

### 4. Firefox-Addons
In `programs/firefox.nix`:
- **uBlock Origin** und **Privacy Badger** werden über Mozilla Enterprise Policies als `force_installed` eingerichtet.
- Das bedeutet: Die Addons sind in **jedem Profil**, **jedem Fenster** und **jeder Sitzung** automatisch aktiv und können vom Nutzer nicht deinstalliert werden.
- Zusätzlich werden Telemetrie, Firefox-Studien und Pocket deaktiviert.

### 5. Firewall
In `networking/firewall.nix`:
- Firewall ist **aktiviert**.
- Alle eingehenden Ports sind standardmäßig **geschlossen**.
- Kommentierte Beispiele für Vaultwarden- und KDE-Connect-Ports.

### 6. Lokalisierung
- **Zeitzone**: `Europe/Berlin`
- **Sprache**: `de_DE.UTF-8` (alle LC_*-Variablen)
- **Tastatur**: Deutsches Layout (X11 + TTY)

### 7. Zusätzliche Pakete
Alle gewünschten Pakete sind in `programs/packages.nix` und den jeweiligen Modul-Dateien installiert:

| Paket | Modul |
|---|---|
| Firefox | `programs/firefox.nix` |
| Chromium | `programs/chromium.nix` |
| Thunderbird | `programs/packages.nix` |
| LibreOffice (Qt) | `programs/packages.nix` |
| Darktable | `programs/packages.nix` |
| GIMP | `programs/packages.nix` |
| VLC | `programs/packages.nix` |
| Audacity | `programs/packages.nix` |
| Neovim | `programs/neovim.nix` |
| sops + age | `programs/packages.nix` |
| Vaultwarden | `services/vaultwarden.nix` |

### 8. SOPS (Secrets-Management)
In `security/sops.nix`:
- **sops-nix** ist als Flake-Input eingebunden.
- **age** ist als Verschlüsselungs-Backend konfiguriert.
- Beispiel-Secrets (auskommentiert) für Vaultwarden und Benutzer-Passwort.
- Schlüssel wird beim ersten Build automatisch unter `/var/lib/sops-nix/key.txt` erzeugt.

### 9. Audio
PipeWire als Audio-Server mit PulseAudio-Kompatibilität und ALSA-Unterstützung.

### 10. SSH
OpenSSH-Server mit deaktiviertem Root-Login und deaktivierter Passwort-Authentifizierung (nur SSH-Keys).

---

## Installation – Schritt für Schritt

### Voraussetzungen
- NixOS ist mit dem graphischen Installer installiert (ISO: `nixos-25.11 unstable`).
- Du hast `sudo`-Zugriff.

### 1. Hardware-Konfiguration erzeugen

```bash
sudo nixos-generate-config --show-hardware-config > /tmp/hw.nix
```

Ersetze den Inhalt von `hardware-configuration.nix` durch die Ausgabe:

```bash
cp /tmp/hw.nix ~/nixos-config/hardware-configuration.nix
```

### 2. NVIDIA Bus-IDs überprüfen

```bash
lspci | grep -E '(VGA|3D)'
```

Typische Ausgabe:

```
00:02.0 VGA compatible controller: Intel ...
01:00.0 3D controller: NVIDIA ...
```

Die Hex-Adressen (`00:02.0` → `PCI:0:2:0`, `01:00.0` → `PCI:1:0:0`) sollten mit den Werten in `modules/hardware/nvidia.nix` übereinstimmen. Falls nicht, anpassen.

### 3. Benutzername anpassen

Öffne `modules/users/hauptnutzer.nix` und ersetze `nutzer` durch deinen gewünschten Benutzernamen:

```nix
users.users.DEIN_NAME = {
  ...
};
```

### 4. Hostname anpassen (optional)

In `modules/networking/networkmanager.nix`:
```nix
networking.hostName = "mein-laptop";
```

### 5. Konfiguration kopieren

```bash
sudo mkdir -p /etc/nixos
sudo cp -r ~/nixos-config/* /etc/nixos/
sudo cp ~/nixos-config/.sops.yaml /etc/nixos/
```

Oder besser – ein Git-Repository verwenden (empfohlen):

```bash
cd ~/nixos-config
git init
git add .
git commit -m "Initiale NixOS-Konfiguration"

# Symlink statt Kopie:
sudo ln -sf ~/nixos-config/flake.nix /etc/nixos/flake.nix
```

### 6. System bauen und aktivieren

```bash
cd /etc/nixos   # oder dein Repo-Verzeichnis
sudo nixos-rebuild switch --flake .#thinkpad-p15
```

### 7. Passwort ändern

Nach dem ersten Login (Passwort: `changeme`):

```bash
passwd
```

---

## SOPS einrichten (Secrets)

### 1. age-Schlüssel erzeugen

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Notiere den **Public Key** aus der Ausgabe (beginnt mit `age1...`).

### 2. `.sops.yaml` anpassen

Trage deinen Public Key in `.sops.yaml` ein:

```yaml
keys:
  - &admin age1dein_public_key_hier

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *admin
```

### 3. Secrets verschlüsseln

```bash
sops secrets/secrets.yaml
```

SOPS öffnet deinen Editor. Trage deine Secrets ein und speichere. Die Datei wird beim Schließen automatisch verschlüsselt.

### 4. Secrets in der Konfiguration verwenden

Kommentiere die gewünschten Secrets in `modules/security/sops.nix` ein:

```nix
sops.secrets."vaultwarden/admin_token" = {
  owner = "vaultwarden";
};
```

In der Vaultwarden-Konfiguration kannst du dann darauf verweisen:

```nix
services.vaultwarden.config = {
  ADMIN_TOKEN_FILE = config.sops.secrets."vaultwarden/admin_token".path;
};
```

### Visualisierung: SOPS-Workflow

```
┌──────────────┐     sops encrypt     ┌──────────────────┐
│  Klartext-   │ ───────────────────► │  Verschlüsselte  │
│  secrets.yaml│                      │  secrets.yaml     │
│  (lokal)     │ ◄─────────────────── │  (im Git-Repo)   │
└──────────────┘     sops decrypt     └────────┬─────────┘
                                               │
                                    nixos-rebuild switch
                                               │
                                               ▼
                                    ┌──────────────────┐
                                    │  /run/secrets/    │
                                    │  (entschlüsselt,  │
                                    │   nur zur         │
                                    │   Laufzeit)       │
                                    └──────────────────┘
```

---

## Was du als Nächstes tun kannst

### Sofort
- [ ] `hardware-configuration.nix` mit echten Werten ersetzen (Schritt 1)
- [ ] Benutzername anpassen (Schritt 3)
- [ ] NVIDIA Bus-IDs prüfen (Schritt 2)
- [ ] `sudo nixos-rebuild switch --flake .#thinkpad-p15` ausführen

### Kurzfristig
- [ ] SOPS einrichten und das initiale Passwort (`changeme`) durch ein verschlüsseltes Secret ersetzen.
- [ ] Vaultwarden aufrufen unter `http://localhost:8000` und einen Account erstellen. Danach `SIGNUPS_ALLOWED = false` setzen.
- [ ] Git-Repository einrichten, damit Änderungen versioniert sind.

### Empfohlene Erweiterungen

| Erweiterung | Beschreibung | Wo hinzufügen |
|---|---|---|
| **Home-Manager** | Benutzerspezifische dotfiles deklarativ verwalten | `flake.nix` als weiteren Input + `modules/users/` |
| **Impermanence** | `/` bei jedem Boot zurücksetzen (stateless) | Neuer Ast `modules/impermanence/` |
| **Disko** | Festplattenpartitionierung deklarativ | `flake.nix` Input + `modules/hardware/disks.nix` |
| **Stylix/Catppuccin** | System-weites Farbschema | Neuer Ast `modules/theming/` |
| **Flatpak** | Für proprietäre Apps, die nicht in nixpkgs sind | `modules/programs/flatpak.nix` |
| **Docker/Podman** | Container-Runtime | `modules/services/docker.nix` |
| **Syncthing** | Datei-Synchronisation | `modules/services/syncthing.nix` |
| **Tailscale/WireGuard** | VPN | `modules/networking/vpn.nix` |

### Neues Modul hinzufügen (Dendritic Pattern)

Um z. B. Docker hinzuzufügen:

1. Neue Datei erstellen:

```nix
# modules/services/docker.nix
{ ... }:
{
  virtualisation.docker.enable = true;
  users.users.nutzer.extraGroups = [ "docker" ];
}
```

2. Import in `modules/services/default.nix` ergänzen:

```nix
imports = [
  ./pipewire.nix
  ./printing.nix
  ./vaultwarden.nix
  ./openssh.nix
  ./docker.nix         # ← NEU
];
```

3. Rebuild:

```bash
sudo nixos-rebuild switch --flake .#thinkpad-p15
```

Das ist das Schöne am Dendritic Pattern: eine Datei, ein Import, fertig.

---

## Nützliche Befehle

```bash
# System aktualisieren (Flake-Inputs + Rebuild)
nix flake update
sudo nixos-rebuild switch --flake .#thinkpad-p15

# Nur testen, ohne zu aktivieren
sudo nixos-rebuild test --flake .#thinkpad-p15

# Vorherige Generation booten (Rollback)
sudo nixos-rebuild switch --rollback

# Garbage Collection (manuell)
sudo nix-collect-garbage -d

# NVIDIA-GPU-Status prüfen
nvidia-smi

# App auf NVIDIA-GPU starten
nvidia-offload glxgears
nvidia-offload darktable
```

---

## Lizenz

Diese Konfiguration ist frei verwendbar. Viel Spaß mit NixOS!
