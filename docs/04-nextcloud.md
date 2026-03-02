# 04 — Nextcloud (Cloud-Speicher, Kalender, Kontakte)

Voraussetzung: Secrets (02), Netzwerk (03). Nextcloud braucht das sops-Secret `nextcloud-admin-pass`.

---

## Schritt 1: ssd-buffer-Verzeichnis vorbereiten

`ssd-buffer.nix` referenziert den User `nextcloud`, der erst durch das Nextcloud-Modul erstellt wird. Damit kein `unknown user`-Fehler auftritt:

**Server:**

```bash
nano modules/server/storage/ssd-buffer.nix
```

Ändere temporär den nextcloud-Eintrag:

```nix
# Vorher:
"d /srv/ssd-buffer/services/nextcloud    0750 nextcloud nextcloud -"
# Nachher (temporär):
"d /srv/ssd-buffer/services/nextcloud    0750 root root -"
```

> **⚠ Wichtig:** Nach dem ersten erfolgreichen Rebuild den Owner wieder auf `nextcloud nextcloud` ändern und erneut rebuilden.

## Schritt 2: encryption.nix anpassen

**Server:** Nextcloud-Secret mit owner/group aktivieren — das geht erst, wenn der Dienst im gleichen Rebuild aktiviert wird:

```bash
nano modules/server/security/encryption.nix
```

```nix
"nextcloud-admin-pass" = {
  owner = "nextcloud";
  group = "nextcloud";
};
```

> **⚠ Aus Doc 02 gelernt:** owner/group funktioniert nur, wenn der Dienst **im gleichen Rebuild** aktiviert wird (d.h. `nextcloud.nix` ist in `default.nix` einkommentiert). Der Dienst erstellt den User `nextcloud` als Teil seines Moduls.

## Schritt 3: Dienst aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/services/default.nix
```

`./nextcloud.nix` einkommentieren.

## Schritt 4: Rebuild

**Server:**

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
# Erster Start: 2-5 Minuten (Datenbank-Initialisierung)
```

### Mögliche Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `unknown user nextcloud` | encryption.nix hat owner/group aber Dienst ist nicht aktiviert | Entweder Dienst im gleichen Rebuild aktivieren ODER owner/group entfernen |
| `attribute 'nextcloud30' missing` | nixpkgs hat neuere Version | **Server:** In `nextcloud.nix` ändern: `pkgs.nextcloud30` → `pkgs.nextcloud31` (oder aktuell) |
| `the key 'nextcloud-admin-pass' cannot be found` | Key fehlt in secrets.yaml | **Laptop:** `sops -d secrets/secrets.yaml \| grep nextcloud` prüfen |

## Schritt 5: Status prüfen

**Server:**

```bash
sudo systemctl status phpfpm-nextcloud
sudo systemctl status nginx
sudo systemctl status postgresql
```

## Schritt 6: ssd-buffer.nix korrigieren

**Server:** Jetzt wo Nextcloud läuft, den Owner zurücksetzen:

```bash
nano modules/server/storage/ssd-buffer.nix
```

```nix
"d /srv/ssd-buffer/services/nextcloud    0750 nextcloud nextcloud -"
```

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 7: Erster Login

1. **Laptop/Browser:** `https://nextcloud.home.lan`
2. Login: **philip** / Passwort aus: **Server:** `sudo cat /run/secrets/nextcloud-admin-pass`
3. Passwort in Vaultwarden speichern (sobald Vaultwarden läuft)

## Empfohlene Apps

Unter Benutzerbild → Apps: **Calendar**, **Contacts**, **Notes**, **Tasks**, **Deck** installieren.

## CalDAV/CardDAV-Clients

- **Thunderbird:** Konto → Kalender → Im Netzwerk → URL: `https://nextcloud.home.lan/remote.php/dav`
- **DAVx5 (Android):** Neues Konto → Basis-URL: `https://nextcloud.home.lan` (Caddy Root-CA muss installiert sein!)
- **Nextcloud Desktop Client:** Server-Adresse: `https://nextcloud.home.lan`

## Fehlerbehebung

**502 Bad Gateway:** **Server:** `sudo systemctl restart phpfpm-nextcloud`

**"Access through untrusted domain":** **Server:** `sudo -u nextcloud php /var/lib/nextcloud/occ config:system:get trusted_domains` — muss `nextcloud.home.lan` enthalten.
