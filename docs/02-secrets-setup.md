# 02 — Secrets-Setup mit SOPS & age

Voraussetzung: NixOS installiert (Anleitung 00), ZFS-Pool erstellt (Anleitung 01).

---

## Übersicht

SOPS verschlüsselt Secrets (Passwörter, Tokens) so, dass sie im Git-Repo liegen
können, ohne lesbar zu sein. Nur Maschinen mit dem richtigen Schlüssel können
sie entschlüsseln.

Da wir **ein Repo für beide Maschinen** nutzen, entfällt das mühsame Kopieren
von `secrets.yaml` zwischen Laptop und Server — beide greifen auf die gleiche
Datei zu.

```
┌──────────────────────────────────────────────┐
│  secrets/secrets.yaml (verschlüsselt im Git) │
│                                              │
│  nextcloud-admin-pass: ENC[AES256_GCM,...]   │
│  vaultwarden-env: ENC[AES256_GCM,...]        │
│  forgejo-secret: ENC[AES256_GCM,...]         │
└──────────┬───────────────┬───────────────────┘
           │               │
     ┌─────┴─────┐   ┌────┴──────┐
     │  Laptop   │   │  Server   │
     │  age-Key  │   │ SSH-Host- │
     │ (keygen)  │   │ Key→age   │
     └───────────┘   └───────────┘
```

---

## Schritt 1: Age-Key auf dem Laptop

Falls du noch keinen age-Key hast:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

> Falls `file exists`: Der Key existiert schon. Public Key auslesen:

```bash
age-keygen -y ~/.config/sops/age/keys.txt
# Ausgabe: age1... (komplett lowercase!)
```

Notiere diesen Public Key — das ist der `&laptop`-Key.

> **⚠ LESSON LEARNED:** Age Public Keys sind **immer komplett lowercase**.
> Großbuchstaben (z.B. `age1XXXX...`) sind Platzhalter und verursachen
> `malformed recipient: mixed case`-Fehler.

## Schritt 2: Server-Key ermitteln

Auf dem **Laptop** (der Server muss laufen):

```bash
ssh-keyscan 192.168.1.10 | ssh-to-age
# Ausgabe: age1... (komplett lowercase!)
```

> Falls `ssh-to-age` nicht installiert: `nix-shell -p ssh-to-age`

Notiere diesen Public Key — das ist der `&homeserver`-Key.

## Schritt 3: `.sops.yaml` aktualisieren

Auf dem **Laptop** im Repo:

```bash
cd ~/nixos-config
nano .sops.yaml
```

Trage die echten Keys ein:

```yaml
keys:
  - &homeserver age1abc...dein-echter-server-key...
  - &laptop age1xyz...dein-echter-laptop-key...

creation_rules:
  - path_regex: secrets/secrets\.yaml$
    key_groups:
      - age:
          - *homeserver
          - *laptop
```

## Schritt 4: Secrets-Datei erstellen

```bash
cd ~/nixos-config
nano secrets/secrets.yaml
```

Trage die Secrets als **flache Keys** ein (keine Verschachtelung!):

```yaml
nextcloud-admin-pass: ein-temporaeres-passwort
vaultwarden-env: ADMIN_TOKEN=hier-einen-token-generieren
forgejo-secret: hier-einen-token-generieren
paperless-secret-key: hier-einen-token-generieren
authentik-secret-key: hier-einen-token-generieren
restic-repo-password: hier-ein-passwort
offsite-backup-password: hier-ein-passwort
```

> **Tokens generieren:**
> ```bash
> openssl rand -base64 48
> ```

> **⚠ LESSON LEARNED:** Die Key-Namen in `secrets.yaml` müssen **1:1** den
> Namen in `encryption.nix` entsprechen. Verschachtelte YAML-Strukturen wie
> `vaultwarden: admin_token: xxx` funktionieren NICHT — sops-nix erwartet
> flache Keys auf der obersten Ebene.

## Schritt 5: Verschlüsseln

```bash
cd ~/nixos-config
sops --encrypt --in-place secrets/secrets.yaml
```

Prüfen:

```bash
head -5 secrets/secrets.yaml
# Muss verschlüsselten Text zeigen: ENC[AES256_GCM,data:...
# NICHT: nextcloud-admin-pass: mein-klartext-passwort
```

> **⚠ LESSON LEARNED:** `sops datei.yaml` (ohne `--encrypt`) erwartet eine
> *bereits verschlüsselte* Datei und öffnet sie zum Editieren. Für die
> Erstverschlüsselung **muss** `sops --encrypt --in-place` verwendet werden.

## Schritt 6: In Git einchecken

```bash
git add .sops.yaml secrets/secrets.yaml
git commit -m "Verschlüsselte Secrets hinzugefügt"
git push
```

> **⚠ LESSON LEARNED:** Nix Flakes sehen **nur Dateien im Git-Index**.
> Eine nicht-committete `secrets.yaml` verursacht:
> `error: path '.../secrets/secrets.yaml' does not exist`

## Schritt 7: Auf den Server bringen

Da beide Maschinen das **gleiche Repo** nutzen, einfach:

```bash
# Auf dem Server:
cd ~/nixos-config
git pull
```

Falls der Server das Repo noch nicht hat:

```bash
# Auf dem Server:
cd ~
git clone git@github.com:Mudslider/nixos-config.git
```

> **Alter Workflow (nicht mehr nötig):** Früher musste `secrets.yaml` manuell
> per `cat`/`nano` vom Laptop auf den Server kopiert werden, weil es zwei
> getrennte Repos gab. Mit dem vereinten Repo entfällt das komplett.

## Schritt 8: encryption.nix aktivieren

**Server:**

```bash
cd ~/nixos-config
nano modules/server/security/encryption.nix
```

Den `secrets`-Block einkommentieren — aber **ohne `owner`/`group`**:

```nix
secrets = {
  "nextcloud-admin-pass" = {};
  "vaultwarden-env" = {};
  "forgejo-secret" = {};
  "paperless-secret-key" = {};
  "authentik-secret-key" = {};
  "restic-repo-password" = {};
  "offsite-backup-password" = {};
};
```

> **⚠ LESSON LEARNED:** `owner` und `group` (z.B. `owner = "nextcloud"`)
> erst setzen, wenn der zugehörige Dienst im **gleichen Rebuild** aktiviert
> wird. Sonst: `failed to lookup user 'nextcloud': unknown user`.

## Schritt 9: Rebuild

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### Mögliche Fehler

| Fehler | Ursache | Lösung |
|--------|---------|--------|
| `the key 'xxx' cannot be found` | Key-Name in `secrets.yaml` ≠ `encryption.nix` | Namen 1:1 angleichen |
| `Error getting data key: 0 successful groups` | Server-Key fehlt als Empfänger | **Laptop:** `sops updatekeys secrets/secrets.yaml`, committen, auf Server pullen |
| `unknown user forgejo` | `owner`/`group` gesetzt, aber Dienst noch nicht aktiv | `owner`/`group` entfernen |
| `malformed recipient: mixed case` | Platzhalter-Key statt echtem Key in `.sops.yaml` | Echte Keys eintragen (lowercase!) |
| `path '.../secrets.yaml' does not exist` | Datei nicht im Git-Index | `git add secrets/secrets.yaml && git commit` |

## Schritt 10: Secrets verifizieren

```bash
sudo ls /run/secrets/
# nextcloud-admin-pass  vaultwarden-env  forgejo-secret  ...

sudo cat /run/secrets/vaultwarden-env
# ADMIN_TOKEN=dein-generierter-token
```

---

## Checkliste

- [ ] Laptop: age-Key existiert in `~/.config/sops/age/keys.txt`
- [ ] Server-Key ermittelt via `ssh-keyscan | ssh-to-age`
- [ ] `.sops.yaml`: Beide echten Keys eingetragen (lowercase!)
- [ ] `secrets.yaml`: Flache Keys, Namen 1:1 mit `encryption.nix`
- [ ] `secrets.yaml` verschlüsselt (`sops --encrypt --in-place`)
- [ ] Alles committed und gepusht
- [ ] Server: `git pull` + Rebuild erfolgreich
- [ ] `/run/secrets/` enthält die entschlüsselten Dateien
- [ ] Keine `owner`/`group` für noch-nicht-aktive Dienste

---

## Nützliche SOPS-Befehle

```bash
# Secrets editieren (öffnet entschlüsselt, speichert verschlüsselt):
sops secrets/secrets.yaml

# Entschlüsselt anzeigen (ohne zu editieren):
sops -d secrets/secrets.yaml

# Nach Änderung an .sops.yaml: Alle Empfänger aktualisieren:
sops updatekeys secrets/secrets.yaml

# Einzelnen Wert prüfen:
sops -d secrets/secrets.yaml | grep vaultwarden
```

---

## Nächste Schritte

→ **Anleitung 03:** Netzwerk und Caddy aufsetzen
