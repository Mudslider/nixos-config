# 18 — Systemhärtung (nach abgeschlossener Installation)

Erst ausführen, wenn **alle Dienste laufen und getestet sind**.

---

## Passwort-Übersicht: Was wird wo gehärtet?

| Passwort | Installationswert | Härtungswert | Wo ändern |
|----------|------------------|--------------|-----------|
| ZFS-Pool | `tank` | 20+ Zeichen | `sudo zfs change-key tank` |
| User (philip) | `server` | SOPS-Secret oder deaktiviert | `hosts/homeserver/default.nix` |
| SSH Passwort-Auth | `true` | `false` | `hosts/homeserver/default.nix` |
| SSH-Key Passphrase | *(leer)* | Optional setzen | `ssh-keygen -p` auf dem Laptop |
| SOPS-Secrets | Generierte Tokens | Bleiben (schon sicher) | — |

---

## Schritt 1: SSH absichern

### 1.1 Sicherstellen, dass Key-Login funktioniert

```bash
# Vom Laptop:
ssh philip@192.168.1.10
# Muss OHNE Passwort-Eingabe funktionieren (nur ggf. Key-Passphrase)
```

### 1.2 Passwort-Auth deaktivieren

**Server:**

```bash
cd ~/nixos-config
nano hosts/homeserver/default.nix
```

Ändern:

```nix
PasswordAuthentication = false;
KbdInteractiveAuthentication = false;
```

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

### 1.3 SSH-Key Passphrase setzen (optional)

**Laptop:**

```bash
ssh-keygen -p -f ~/.ssh/id_ed25519
# Altes Passwort: Enter (leer)
# Neues Passwort: starkes Passwort eingeben
```

Danach `ssh-agent` nutzen:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
# Einmalig Passphrase eingeben — gilt für die gesamte Session
```

---

## Schritt 2: User-Passwort absichern

### Option A: Starkes Passwort über SOPS

In `hosts/homeserver/default.nix` ändern:

```nix
# Vorher:
initialPassword = "server";

# Nachher:
hashedPasswordFile = config.sops.secrets."user-password-hash".path;
```

In `modules/server/security/encryption.nix` ergänzen:

```nix
"user-password-hash" = {};
```

Hash generieren und in SOPS eintragen:

```bash
mkpasswd -m sha-512 "dein-starkes-passwort"
sops secrets/secrets.yaml
# Zeile hinzufügen: user-password-hash: $6$...
```

### Option B: Passwort deaktivieren (nur SSH-Key)

```nix
# initialPassword = "server";  ← Zeile löschen
```

Ohne Passwort ist Konsolen-Login unmöglich — Rettung nur per USB-Stick.

---

## Schritt 3: ZFS-Passphrase stärken

```bash
# Pool muss entsperrt sein:
sudo zfs load-key tank  # falls noch nicht geschehen

# Neue Passphrase setzen:
sudo zfs change-key -o keyformat=passphrase tank
# Altes Passwort eingeben ("tank"), dann neues (20+ Zeichen)
```

### Alternative: Keyfile auf SSD (automatischer Unlock)

Weniger sicher — schützt nur gegen HDD-Diebstahl ohne SSD:

```bash
sudo dd if=/dev/urandom of=/root/.zfs-keyfile bs=32 count=1
sudo chmod 600 /root/.zfs-keyfile
sudo zfs change-key -o keyformat=raw -o keylocation=file:///root/.zfs-keyfile tank
```

Dann in `modules/server/hardware/zfs.nix` den `systemd.services.zfs-load-key`-Block einkommentieren.

---

## Schritt 4: SOPS-Secrets prüfen

Falls du in der Installationsphase zu einfache Werte gewählt hast:

```bash
sops secrets/secrets.yaml
# Werte mit: openssl rand -base64 48 ersetzen

git add secrets/secrets.yaml
git commit -m "Secrets rotiert"
git push
# Auf dem Server: git pull && sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

---

## Schritt 5: Firewall prüfen

```bash
sudo iptables -L -n --line-numbers
```

Erwartet:
- TCP 22: Nur 192.168.1.0/24
- TCP 443: Offen (Caddy)
- Alles andere: DROP

---

## Schritt 6: Committen

```bash
cd ~/nixos-config
git add -A
git commit -m "Systemhärtung: SSH + Passwörter + ZFS"
git push
```

---

## Checkliste

- [ ] SSH: Key-Login funktioniert
- [ ] SSH: `PasswordAuthentication = false`
- [ ] SSH-Key: Optional Passphrase gesetzt
- [ ] User: `initialPassword` ersetzt oder entfernt
- [ ] ZFS: Starke Passphrase (oder bewusst Keyfile)
- [ ] SOPS: Alle Secrets mit sicheren Werten
- [ ] Firewall: Nur erwartete Ports offen
- [ ] Alles committed und gepusht

---

## Notfall-Recovery

Falls du dich nach der Härtung aussperrst:

1. USB-Stick mit NixOS-ISO bereithalten
2. Vom USB booten
3. Mounten: `mount /dev/nvme0n1p2 /mnt && mount /dev/nvme0n1p1 /mnt/boot`
4. Config editieren: `nano /mnt/home/philip/nixos-config/hosts/homeserver/default.nix`
   → `PasswordAuthentication = true;`
5. Neu installieren: `nix-env -iA nixos.nix && nixos-install --flake /mnt/home/philip/nixos-config#homeserver --no-root-passwd`
6. Reboot, USB raus
