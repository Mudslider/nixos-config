# 99 — Neuen Dienst zum Homeserver hinzufügen

Allgemeine Anleitung + Checkliste + Port-Liste.

---

## Workflow-Übersicht

Alle Änderungen werden auf dem **Laptop** editiert, committet und gepusht.
Der Server zieht die Änderungen per `nrs`-Alias (git fetch + reset + rebuild).

---

## NixOS-Modul oder Podman-Container?

Prüfe auf https://search.nixos.org/options ob ein Modul existiert (`services.DIENSTNAME`). Falls ja, nutze das Modul. Falls nein, Container.

Beispiele in der Config:
- **NixOS-Module:** Jellyfin, Navidrome, Vaultwarden, Forgejo, Home Assistant, Netdata, Syncthing
- **Podman-Container:** Immich, PaperlessNGX, Authentik, Audiobookshelf, Uptime Kuma, RustDesk

---

## Variante A: NixOS-Modul

### 1. Modul-Datei erstellen

```bash
nano ~/nixos-config/modules/server/services/mein-dienst.nix
```

```nix
{ config, pkgs, ... }:

{
  services.mein-dienst = {
    enable = true;
    settings = {
      listen = "127.0.0.1";   # NUR localhost, Caddy macht den Rest
      port = XXXXX;            # Freien Port wählen (siehe unten)
    };
  };
}
```

### 2. In default.nix importieren

```bash
nano ~/nixos-config/modules/server/services/default.nix
# Füge hinzu: ./mein-dienst.nix
```

### 3. Caddy-VirtualHost einkommentieren/hinzufügen

```bash
nano ~/nixos-config/modules/server/networking/caddy.nix
```

```nix
"mein-dienst.home.lan" = {
  extraConfig = ''
    tls internal
    reverse_proxy localhost:XXXXX
  '';
};
```

### 4. DNS-Eintrag

Bei Wildcard-DNS automatisch. Sonst: pfSense → `mein-dienst.home.lan → 192.168.178.10`

### 5. Datenverzeichnis in ssd-buffer.nix

```bash
nano ~/nixos-config/modules/server/storage/ssd-buffer.nix
# Hinzufügen (zuerst mit root:root, nach Aktivierung korrigieren):
# "d /srv/ssd-buffer/services/mein-dienst 0750 root root -"
```

### 6. Deployen

```bash
# Laptop: committen + pushen
cd ~/nixos-config && git add -A && git commit -m "feat: mein-dienst hinzufügen" && git push

# Server: nrs-Alias (fetch + reset + rebuild)
nrs
```

---

## Variante B: Podman-Container

### Einfacher Container

```nix
# modules/server/services/mein-dienst.nix
{ pkgs, ... }:

{
  virtualisation.oci-containers.containers.mein-dienst = {
    image = "docker.io/herausgeber/mein-dienst:1.2.3";  # Nie :latest!
    ports = [ "XXXXX:8080" ];
    volumes = [
      "/srv/ssd-buffer/services/mein-dienst/data:/data"
    ];
    environment = {
      TZ = "Europe/Berlin";
    };
    autoStart = true;
  };
}
```

> **Aus Doc 02 gelernt:** Bei `tmpfiles.rules` keinen Service-User verwenden, solange der Dienst nicht aktiv ist! Immer erst `root root`, nach dem ersten Rebuild den richtigen User eintragen.

### Container mit Datenbank (eigenes Netzwerk)

Wenn der Dienst PostgreSQL/Redis braucht:

1. Podman-Netzwerk in `podman.nix` einkommentieren/hinzufügen
2. Container mit `extraOptions = ["--network=NAME"]`
3. systemd-Abhängigkeiten mit `.after`

Siehe `modules/server/services/immich.nix` als Referenz.

Dann: Import in `default.nix`, Caddy-VirtualHost, DNS, Deployen — wie bei Variante A.

---

## Belegte Ports (NICHT verwenden!)

```
22      SSH                 443     Caddy HTTPS
2222    Forgejo SSH         2283    Immich
3000    Forgejo HTTP        3001    Uptime Kuma
4533    Navidrome           8000    PaperlessNGX
8080    Nextcloud (nginx)   8096    Jellyfin
8100    Restic REST         8123    Home Assistant
8222    Vaultwarden         8384    Syncthing (localhost)
9000    Authentik           13378   Audiobookshelf
19999   Netdata             21115-8 RustDesk
51820   NetBird
```

**Freie Bereiche:** 5000-5999, 7000-7999, 9001-9999, 10000-13377

---

## Secrets für neuen Dienst

Da beide Maschinen dasselbe Repo nutzen, werden Secrets auf dem **Laptop** bearbeitet.
Der Server entschlüsselt sie automatisch über seinen SSH-Host-Key.

### 1. Secret in secrets.yaml eintragen

**Laptop:**

```bash
cd ~/nixos-config
sops secrets/secrets.yaml
# Neuen Key hinzufügen, z.B.: mein-dienst-secret: "generiertes-passwort"
# Speichern
```

### 2. Keys aktualisieren (falls nötig)

Falls ein neuer Rechner dazukommt oder ein Key geändert wurde:

```bash
sops updatekeys secrets/secrets.yaml
```

### 3. Secret in encryption.nix deklarieren

```bash
nano modules/server/security/encryption.nix
# Im secrets-Block hinzufügen:
# "mein-dienst-secret" = {};
```

> **Kein `owner`/`group` beim ersten Rebuild**, falls der Dienst den User erst erstellt!

### 4. Im Modul referenzieren

```nix
# In der Dienst-Config:
passwordFile = config.sops.secrets."mein-dienst-secret".path;
# Zur Laufzeit: /run/secrets/mein-dienst-secret
```

### 5. Deployen

```bash
# Laptop:
git add -A && git commit -m "feat: secrets für mein-dienst" && git push

# Server:
nrs
```

### 6. Prüfen

```bash
sudo ls /run/secrets/
sudo cat /run/secrets/mein-dienst-secret
```

---

## Checkliste

- [ ] Port gewählt (nicht belegt, siehe Liste oben)
- [ ] Modul-Datei erstellt (`modules/server/services/`)
- [ ] In `modules/server/services/default.nix` importiert
- [ ] Caddy-VirtualHost in `modules/server/networking/caddy.nix`
- [ ] DNS-Eintrag (oder Wildcard) in pfSense
- [ ] Datenverzeichnis in `ssd-buffer.nix` mit `root root`
- [ ] Secrets: sops-Key auf Laptop → `encryption.nix` → commit + push
- [ ] Server: `nrs` (fetch + rebuild)
- [ ] ssd-buffer.nix: Owner auf Service-User korrigieren, nochmal deployen
- [ ] encryption.nix: owner/group für Secret setzen, nochmal deployen
- [ ] Erster Login + Passwort in Vaultwarden speichern
- [ ] Git commit + push

---

## Häufige Fehler (Kurzreferenz aus Doc 02)

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `unknown user` | owner/group für inaktiven Dienst | owner/group entfernen, erst nach Aktivierung setzen |
| `the key '...' cannot be found` | Key fehlt in secrets.yaml | Key in sops eintragen, `git add`, rebuild |
| `Error getting data key: 0 successful groups` | Server-Key fehlt | `sops updatekeys secrets/secrets.yaml` |
| `path does not exist` | Datei nicht im Git | `git add`, `git commit` |
| Nix-Syntaxfehler | Klammern falsch | `nix-instantiate --parse datei.nix` zum Prüfen |
