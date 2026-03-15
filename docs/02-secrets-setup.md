# 02 – Secrets-Setup mit SOPS & age (Lessons Learned)

## Übersicht

Dieses Dokument fasst alle Fehler, Lösungen und Erkenntnisse zusammen, die beim Einrichten von SOPS-Secrets und der Basisstabilisierung des NixOS-Homeservers aufgetreten sind.

**Umgebung:**
- Laptop (`polly@playground`): `~/nixos-config` → Repo `github.com/Mudslider/nixos-config`
- Server (`philip@homeserver`): `~/nixos-config` → gleiches Repo (via `git pull`)
- Workflow: Auf dem Laptop editieren → `git push` → auf dem Server `git pull` → `sudo nixos-rebuild switch`

---

## Fehler beim SOPS-Setup

### 1. „mixed case" beim age-Key

**Fehlermeldung:**
```
failed to parse input as Bech32-encoded age public key:
malformed recipient "age1XXXX...": mixed case
```

**Ursache:** Platzhalter-Keys mit Großbuchstaben in `.sops.yaml` oder `secrets.yaml`.

**Lösung (Laptop):**
```bash
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt   # zeigt Public Key
```

**Lesson Learned:** Age verwendet Bech32-Encoding – Public Keys sind immer komplett lowercase.

---

### 2. secrets.yaml war nicht verschlüsselt

**Symptom:** `sops secrets/secrets.yaml` schlug fehl, weil die Datei noch Klartext war.

**Lösung (Laptop):**
```bash
# Erstmalig verschlüsseln:
sops --encrypt --in-place secrets/secrets.yaml

# Danach interaktiv editieren:
sops secrets/secrets.yaml
```

**Lesson Learned:** `sops <datei>` erwartet eine bereits verschlüsselte Datei. Für Erstverschlüsselung `--encrypt --in-place` verwenden.

---

### 3. secrets.yaml nicht im Git

**Fehlermeldung:**
```
error: path '/nix/store/...-source/secrets/secrets.yaml' does not exist
```

**Ursache:** Nix Flakes sehen nur Dateien im Git-Index.

**Lösung (Laptop):**
```bash
git add secrets/secrets.yaml .sops.yaml
git commit -m "add encrypted secrets"
git push
```

**Lesson Learned:** Neue Dateien müssen immer `git add` + `git commit` bekommen, bevor ein Rebuild sie sehen kann.

---

### 4. Server-Key nicht in .sops.yaml

**Fehlermeldung (Server):**
```
Error getting data key: 0 successful groups required, got 0
```

**Ursache:** `secrets.yaml` war nur für den Laptop-Key verschlüsselt, nicht für den Server.

**Lösung (Laptop):**
```bash
# Server-Key aus SSH-Host-Key ableiten:
nix-shell -p ssh-to-age --run "ssh-keyscan 192.168.178.10 2>/dev/null | ssh-to-age"

# Key in .sops.yaml eintragen, dann:
sops updatekeys secrets/secrets.yaml
```

**Lesson Learned:** Beide age-Keys (Laptop + Server) müssen in `.sops.yaml` stehen. Nach dem Hinzufügen immer `sops updatekeys` ausführen.

---

### 5. YAML-Key-Namen stimmen nicht mit NixOS überein

**Fehlermeldung (Server):**
```
the key 'nextcloud-admin-pass' cannot be found in secrets.yaml
```

**Ursache:** Key in `encryption.nix` hieß `nextcloud-admin-pass`, in `secrets.yaml` aber `nextcloud/admin_pass`.

**Lesson Learned:** Key-Namen in `secrets.yaml` müssen exakt dem Pfad in `encryption.nix` entsprechen. Die sops-nix Option `key` definiert den Pfad in der YAML-Struktur, z.B.:
```nix
"nextcloud-admin-pass" = {
  key = "nextcloud/admin_pass";
};
```

---

### 6. `unknown user` beim Rebuild

**Fehlermeldung (Server):**
```
unknown user 'nextcloud'
```

**Ursache:** `owner = "nextcloud"` in `encryption.nix` gesetzt, aber der Nextcloud-Dienst (der den User anlegt) ist noch nicht aktiviert.

**Lösung:** Keine `owner`/`group` für Dienste setzen, die noch nicht laufen. Erst beim Aktivieren des jeweiligen Dienstes hinzufügen.

---

### 7. Nix-Syntaxfehler in .nix-Dateien

**Fehlermeldung:**
```
error: syntax error, unexpected '}'
```

**Lösung (Laptop):** Syntax vor dem Commit prüfen:
```bash
nix-instantiate --parse datei.nix > /dev/null
```

**Lesson Learned:** Häufige Ursachen: fehlende Semikolons, falsche Klammern, fehlende Kommas in Listen.

---

### 8. `ssh-to-age` nicht installiert

**Fehlermeldung (Laptop):**
```
bash: ssh-to-age: Kommando nicht gefunden
```

**Lösung (Laptop):**
```bash
nix-shell -p ssh-to-age --run "ssh-keyscan 192.168.178.10 2>/dev/null | ssh-to-age"
```

**Lesson Learned:** `ssh-to-age` ist nicht standardmäßig installiert. Immer über `nix-shell -p` aufrufen.

---

### 9. Git-Deprecation-Warnings

**Warnungen (Server, beim Rebuild):**
```
The option 'programs.git.userName' has been renamed to 'programs.git.settings.user.name'
The option 'programs.git.userEmail' has been renamed to 'programs.git.settings.user.email'
The option 'programs.git.extraConfig' has been renamed to 'programs.git.settings'
```

**Lösung (Laptop):** In `home/server/git.nix`:
```nix
# Alt (deprecated):
userName = "Philip";
userEmail = "philip@home.lan";
extraConfig = { ... };

# Neu:
settings = {
  user = {
    name = "Philip";
    email = "philip@home.lan";
  };
  init.defaultBranch = "main";
  pull.rebase = true;
  push.autoSetupRemote = true;
  core.editor = "nano";
};
```

---

## Fehler beim Server-Betrieb

### 10. SSH „Connection refused" nach Inaktivität

**Symptom (Laptop):**
```
ssh: connect to host 192.168.178.10 port 22: Connection refused
```

**Ursache:** Der Server ging in den Schlafmodus. Nach dem Aufwachen (Tastendruck am Monitor) wurden die Firewall-Regeln nicht korrekt geladen, obwohl SSH lief.

**Sofort-Fix (Server):**
```bash
sudo iptables -I INPUT -p tcp --dport 22 -j ACCEPT
```

**Dauerhafter Fix (Laptop):** In `hosts/homeserver/default.nix`:
```nix
systemd.targets.sleep.enable = false;
systemd.targets.suspend.enable = false;
systemd.targets.hibernate.enable = false;
systemd.targets.hybrid-sleep.enable = false;
```

**Prüfung (Server, nach Rebuild):**
```bash
systemctl status sleep.target
# Muss "masked" zeigen
```

**Lesson Learned:** `systemctl mask` funktioniert nicht manuell auf NixOS — der Rebuild überschreibt es. Immer über die NixOS-Config lösen. Ein Headless-Server muss Sleep/Suspend dauerhaft deaktiviert haben.

---

### 11. ZFS-Pool Import schlägt fehl (hostId-Mismatch)

**Fehlermeldung (Server):**
```
cannot import 'tank': pool was previously in use from another system.
Last accessed by homeserver (hostid=8a2c612c)
```

**Ursache:** Der Pool wurde zu einem Zeitpunkt mit einer falschen hostId genutzt (z.B. nach einem Rebuild mit fehlendem/falschem `networking.hostId`).

**Sofort-Fix (Server):**
```bash
sudo zpool import -f tank
```

**Prüfung (Server):**
```bash
hostid          # Muss "687e79ce" zeigen
zpool status tank
```

**⚠ KRITISCH:** `networking.hostId = "687e79ce"` darf NIEMALS geändert werden! Steht in `hosts/homeserver/default.nix`. Bei Merge-Konflikten diesen Wert immer beibehalten.

---

### 12. Restic REST Server — fehlende .htpasswd

**Fehlermeldung (Server):**
```
error: cannot load /srv/ssd-buffer/backup/.htpasswd: no such file or directory
```

**Lösung (Server):**
```bash
sudo mkdir -p /srv/ssd-buffer/backup
nix-shell -p apacheHttpd --run "htpasswd -c /tmp/.htpasswd restic"
# Passwort eingeben (das generierte Restic-Passwort verwenden)
sudo cp /tmp/.htpasswd /srv/ssd-buffer/backup/.htpasswd
sudo systemctl restart restic-rest-server
```

**Lesson Learned:** `openssl` ist auf dem NixOS-Server nicht standardmäßig installiert. `htpasswd` über `nix-shell -p apacheHttpd` nutzen.

---

### 13. `git pull` auf Server schlägt fehl (dirty tree)

**Fehlermeldung (Server):**
```
Pull mit Rebase nicht möglich: Sie haben Änderungen, die nicht zum Commit vorgemerkt sind.
```

**Ursache:** `sudo nixos-rebuild` verändert `flake.lock` und erstellt Dateien als root.

**Lösung (Server):**
```bash
# Erst Berechtigungen fixen:
sudo chown -R philip:users ~/nixos-config

# Dann lokale Änderungen verwerfen:
git reset --hard origin/main
git pull
```

**Lesson Learned:** `flake.lock` wird beim Rebuild aktualisiert. Wenn `git stash` wegen Berechtigungen scheitert, erst `chown`, dann `reset --hard`. Lokale Änderungen auf dem Server vermeiden — immer auf dem Laptop editieren und pushen.

---

### 14. Verschachteltes Repo auf dem Server

**Symptom:** `~/nixos-config/nixos-config/` existiert — ein versehentlicher Clone innerhalb des Repos.

**Lösung (Server):**
```bash
rm -rf ~/nixos-config/nixos-config
```

**Lesson Learned:** Beim `git clone` auf dem Server darauf achten, dass man sich nicht bereits im Repo-Verzeichnis befindet.

---

### 15. Erster `git push` — kein Upstream gesetzt

**Fehlermeldung (Laptop):**
```
Der aktuelle Branch main hat keinen Upstream-Branch.
```

**Lösung (Laptop):**
```bash
git push --set-upstream origin main
```

Danach reicht immer `git push`.

---

## Checkliste: SOPS-Secrets korrekt einrichten

1. **Age-Keys generieren (Laptop):**
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

2. **Server-Key ableiten (Laptop):**
   ```bash
   nix-shell -p ssh-to-age --run "ssh-keyscan 192.168.178.10 2>/dev/null | ssh-to-age"
   ```

3. **`.sops.yaml` anlegen (Laptop)** mit beiden Public Keys (lowercase!)

4. **Secrets generieren (Laptop):**
   ```bash
   NEXTCLOUD_PASS=$(openssl rand -base64 24)
   VAULTWARDEN_TOKEN=$(openssl rand -base64 48)
   FORGEJO_SECRET=$(openssl rand -hex 32)
   PAPERLESS_SECRET=$(openssl rand -hex 32)
   AUTHENTIK_SECRET=$(openssl rand -hex 50)
   RESTIC_PASS=$(openssl rand -base64 32)
   OFFSITE_PASS=$(openssl rand -base64 32)
   ```
   → **Sofort im Passwort-Manager sichern!**

5. **`secrets.yaml` erstellen und verschlüsseln (Laptop):**
   ```bash
   sops --encrypt --in-place secrets/secrets.yaml
   ```

6. **Beide Keys als Empfänger setzen (Laptop):**
   ```bash
   sops updatekeys secrets/secrets.yaml
   ```

7. **In Git einchecken (Laptop):**
   ```bash
   git add secrets/secrets.yaml .sops.yaml
   git commit -m "add encrypted secrets"
   git push
   ```

8. **Auf Server holen (Server):**
   ```bash
   cd ~/nixos-config
   git pull
   ```

9. **`encryption.nix`:** Keine `owner`/`group` für Dienste setzen, die noch nicht laufen

10. **Rebuild (Server):**
    ```bash
    sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
    ```

11. **Secrets verifizieren (Server):**
    ```bash
    sudo ls /run/secrets/
    sudo cat /run/secrets/<key-name>
    ```

---

## Kurzreferenz: Häufige Fehler

| Fehler | Wo | Ursache | Lösung |
|--------|-----|---------|--------|
| `unknown user` | Server | owner/group für inaktiven Dienst | owner/group entfernen |
| `key cannot be found` | Server | Key fehlt in secrets.yaml | **Laptop:** Key in sops eintragen |
| `0 successful groups` | Server | Server-Key fehlt in .sops.yaml | **Laptop:** `sops updatekeys` |
| `path does not exist` | Server | Datei nicht im Git | **Laptop:** `git add`, `commit`, `push` |
| `mixed case` | Laptop | Age-Key mit Großbuchstaben | Alle age-Keys müssen lowercase sein |
| Nix-Syntaxfehler | Server | Klammern/Semikolons falsch | `nix-instantiate --parse datei.nix` |
| `Connection refused` | Laptop | Server schläft / Firewall | Sleep deaktivieren, `iptables` prüfen |
| `hostid` Mismatch | Server | Falscher/fehlender hostId | `sudo zpool import -f tank` |
| `git pull` dirty tree | Server | flake.lock geändert | `git reset --hard origin/main` |

---

## Referenzen

- [sops-nix Dokumentation](https://github.com/Mic92/sops-nix)
- [age Encryption](https://github.com/FiloSottile/age)
- [SOPS – Secrets OPerationS](https://github.com/getsops/sops)
