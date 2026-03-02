# 09 — Forgejo (Git-Server)

Leichtgewichtiger Git-Server. Dein NixOS-Config-Repo gehört hierhin.

Voraussetzung: Secrets (02), Netzwerk (03).

---

## Schritt 1: ssd-buffer.nix vorbereiten

**Server:** `ssd-buffer.nix` referenziert den User `forgejo`, der erst durch das Modul erstellt wird:

```bash
nano modules/server/storage/ssd-buffer.nix
```

Temporär ändern:

```nix
# Vorher:
"d /srv/ssd-buffer/services/forgejo      0750 forgejo   forgejo   -"
# Nachher (temporär):
"d /srv/ssd-buffer/services/forgejo      0750 root root -"
```

## Schritt 2: Dienst aktivieren

**Server:**

```bash
nano modules/server/services/default.nix
# ./forgejo.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 3: ssd-buffer.nix korrigieren

**Server:** Jetzt wo Forgejo läuft und der User existiert:

```bash
nano modules/server/storage/ssd-buffer.nix
# Zurück auf: "d /srv/ssd-buffer/services/forgejo 0750 forgejo forgejo -"

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 4: encryption.nix – owner/group setzen

**Server:** Jetzt ist es auch sicher, den Secret-Owner zu setzen:

```bash
nano modules/server/security/encryption.nix
```

```nix
"forgejo-secret" = {
  owner = "forgejo";
  group = "forgejo";
};
```

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 5: Erster Login

1. **Laptop/Browser:** `https://forgejo.home.lan`
2. **Erstregistrierung:** Der erste Benutzer wird automatisch Admin
3. Als **philip** registrieren — danach ist Registrierung gesperrt

## SSH-Zugang für Git

**Laptop:** SSH-Key in Forgejo hinterlegen: Einstellungen → SSH/GPG-Schlüssel → Schlüssel hinzufügen.

**Laptop:** `~/.ssh/config` ergänzen:

```
Host forgejo.home.lan
    Port 2222
    User git
    IdentityFile ~/.ssh/id_ed25519
```

Dann: `git clone forgejo.home.lan:philip/mein-repo.git`

## NixOS-Config als Repo

**Server:**

```bash
cd ~/nixos-config
# Erstelle das Repo zuerst in der Forgejo Web-UI, dann:
git remote add forgejo ssh://git@forgejo.home.lan:2222/philip/nixos-config.git
git push -u forgejo main
```

> **⚠ `Permission denied (publickey)`:** SSH-Key muss in Forgejo hinterlegt sein, und der Port 2222 muss in `~/.ssh/config` stehen.
