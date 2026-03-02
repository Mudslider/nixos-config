# 99 — Neuen Dienst zum Homeserver hinzufügen

Allgemeine Anleitung + Checkliste + Port-Liste. Alle Schritte auf dem **Server**, außer wo anders angegeben.

---

## NixOS-Modul oder Podman-Container?

Prüfe zuerst auf https://search.nixos.org/options ob ein Modul existiert (`services.DIENSTNAME`). Falls ja, nutze das Modul. Falls nein, Container.

Beispiele in deiner Config:
- **NixOS-Module:** Jellyfin, Navidrome, Vaultwarden, Forgejo, Home Assistant, Netdata, Syncthing
- **Podman-Container:** Immich, PaperlessNGX, Authentik, Audiobookshelf, Uptime Kuma, RustDesk

---

## Variante A: NixOS-Modul

### 1. Modul-Datei erstellen

**Server:**

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

**Server:**

```bash
nano ~/nixos-config/modules/server/services/default.nix
# Füge hinzu: ./mein-dienst.nix
```

### 3. Caddy-VirtualHost

**Server:**

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

Bei Wildcard-DNS (empfohlen) automatisch. Sonst: pfSense → `mein-dienst.home.lan → 192.168.1.10`

### 5. Rebuild

**Server:**

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

---

## Variante B: Podman-Container

### Einfacher Container

**Server:**

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

  systemd.tmpfiles.rules = [
    "d /srv/ssd-buffer/services/mein-dienst 0750 root root -"
  ];
}
```

> **⚠ Aus Doc 02 gelernt:** Bei `tmpfiles.rules` keinen Service-User verwenden (z.B. `forgejo forgejo`), solange der Dienst nicht aktiv ist! Immer erst `root root`, nach dem ersten Rebuild den richtigen User eintragen.

### Container mit Datenbank (eigenes Netzwerk)

Wenn der Dienst PostgreSQL/Redis braucht, nach dem Muster von Immich/PaperlessNGX:
eigenes Podman-Netzwerk erstellen, Container mit `extraOptions = ["--network=NAME"]`,
systemd-Service für das Netzwerk, Abhängigkeiten mit `.after`.

Siehe `modules/server/services/immich.nix` als Referenz.

Dann: Import in `default.nix`, Caddy-VirtualHost, DNS, Rebuild — wie bei Variante A.

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

> **⚠ Die folgenden Schritte betreffen BEIDE Maschinen!**

### 1. Secret in secrets.yaml eintragen

**Laptop:**

```bash
sops ~/nixos-config/secrets/secrets.yaml
# Neuen Key hinzufügen, z.B.: mein-dienst-secret: "generiertes-passwort"
# Speichern mit :wq
```

### 2. Secret in encryption.nix deklarieren

**Server:**

```bash
nano modules/server/security/encryption.nix
# Im secrets-Block hinzufügen:
# "mein-dienst-secret" = {};
```

> **⚠ Kein `owner`/`group` beim ersten Rebuild**, falls der Dienst den User erst erstellt! (Doc 02, Fehler 6)

### 3. secrets.yaml auf den Server kopieren

**Laptop:** `cat ~/nixos-config/secrets/secrets.yaml`

**Server:** `nano ~/nixos-config/secrets/secrets.yaml` → Inhalt ersetzen.

> **⚠ Da Laptop und Server verschiedene Repos nutzen**, muss die secrets.yaml immer manuell kopiert werden (Doc 02, Fehler 4).

### 4. Im Modul referenzieren

**Server:**

```nix
# In der Dienst-Config:
passwordFile = config.sops.secrets."mein-dienst-secret".path;
# Zur Laufzeit wird das zu: /run/secrets/mein-dienst-secret
```

### 5. Rebuild

**Server:**

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### 6. Prüfen

**Server:**

```bash
sudo ls /run/secrets/
sudo cat /run/secrets/mein-dienst-secret
```

---

## Checkliste

- [ ] Port gewählt (nicht belegt, siehe Liste oben)
- [ ] Modul-Datei erstellt (**Server**)
- [ ] In `modules/server/services/default.nix` importiert (**Server**)
- [ ] Caddy-VirtualHost in `modules/server/networking/caddy.nix` (**Server**)
- [ ] DNS-Eintrag (oder Wildcard) (**pfSense**)
- [ ] Datenverzeichnis in `ssd-buffer.nix` mit `root root` (**Server**)
- [ ] Secrets: sops-Key auf **Laptop** → encryption.nix auf **Server** → secrets.yaml kopieren
- [ ] `sudo nixos-rebuild switch --flake ~/nixos-config#homeserver` (**Server**)
- [ ] ssd-buffer.nix: Owner auf Service-User korrigieren, erneut rebuild (**Server**)
- [ ] encryption.nix: owner/group für Secret setzen, erneut rebuild (**Server**)
- [ ] Erster Login + Passwort in Vaultwarden (**Laptop/Browser**)
- [ ] Uptime-Kuma-Monitor hinzufügen (**Laptop/Browser**)
- [ ] Git commit (**Server**)

---

## Updates

### Container-Versionen

**Server:** Image-Tag in der .nix-Datei ändern → rebuild. **Immer erst Changelog lesen!**

```bash
sudo podman image prune -a   # Alte Images aufräumen
```

### NixOS-Module

**Server:**

```bash
cd ~/nixos-config
nix flake update
sudo nixos-rebuild switch --flake .#homeserver

# Rollback falls nötig:
sudo nixos-rebuild switch --rollback
```

---

## Häufige Fehler (Kurzreferenz aus Doc 02)

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `unknown user` | owner/group für inaktiven Dienst | owner/group entfernen, erst nach Aktivierung setzen |
| `the key '...' cannot be found` | Key fehlt in secrets.yaml | **Laptop:** Key in sops eintragen, Datei auf Server kopieren |
| `Error getting data key: 0 successful groups` | Server-Key fehlt | **Laptop:** `sops updatekeys secrets/secrets.yaml` |
| `path does not exist` | Datei nicht im Git | **Server:** `git add`, `git commit` |
| `mixed case` | Age-Key hat Großbuchstaben | Alle age-Keys müssen lowercase sein |
| Nix-Syntaxfehler | Klammern falsch | `nix-instantiate --parse datei.nix` zum Prüfen |
