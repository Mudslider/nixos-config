# 08 — Vaultwarden (Passwort-Manager)

Bitwarden-kompatibler Passwort-Manager. Sollte einer der **ersten Dienste** sein.

Voraussetzung: Secrets (02), Netzwerk (03).

---

## Schritt 1: Authentik-Secret in vaultwarden.nix eintragen

**Server:** In `vaultwarden.nix` steht noch ein leerer `ADMIN_TOKEN`. Dieser sollte aus dem sops-Secret kommen:

```bash
cat modules/server/services/vaultwarden.nix
```

> **⚠ Aktueller Stand:** Die Config nutzt `ADMIN_TOKEN = ""` direkt in der Nix-Datei. Besser wäre, das Secret über `sops.secrets."vaultwarden-env"` zu laden. Für den ersten Start genügt es aber, den Token manuell einzutragen.

**Server:**

```bash
# Den Token aus dem sops-Secret lesen (falls Secrets schon entschlüsselt werden):
sudo cat /run/secrets/vaultwarden-env
# Gibt z.B. aus: ADMIN_TOKEN=eCvPQJuE40n...

# Falls /run/secrets noch nicht existiert, den Wert vom Laptop holen:
```

**Laptop:**

```bash
sops -d ~/nixos-config/secrets/secrets.yaml | grep vaultwarden-env
# Ausgabe: vaultwarden-env: ADMIN_TOKEN=eCvPQJuE40n...
```

**Server:** Token in die Config eintragen (nur den Teil nach `ADMIN_TOKEN=`):

```bash
nano modules/server/services/vaultwarden.nix
# ADMIN_TOKEN = "eCvPQJuE40n...";  (den echten Token eintragen)
```

## Schritt 2: Dienst aktivieren

**Server:**

```bash
nano modules/server/services/default.nix
# ./vaultwarden.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Schritt 3: Admin-Panel

**Laptop/Browser:** `https://vaultwarden.home.lan/admin`

Admin-Token eingeben (der Wert aus Schritt 1).

## Schritt 4: Ersten Benutzer anlegen

Registrierung ist gesperrt (`SIGNUPS_ALLOWED = false`). Benutzer über das Admin-Panel einladen:

1. Admin-Panel → Users → Invite User → deine E-Mail eingeben
2. `https://vaultwarden.home.lan` öffnen → mit eingeladener E-Mail registrieren
3. **Master-Passwort** setzen — dieses Passwort ist NICHT wiederherstellbar!

## Bitwarden-Clients

Browser-Extension, Desktop-App, Android/iOS-App — in jedem Client **vor dem Login** die Server-URL setzen:

```
https://vaultwarden.home.lan
```

> **⚠ Caddy Root-CA** muss auf dem Client installiert sein (Anleitung 03), sonst verweigern die Apps die Verbindung.

## Backup

Automatisches Backup nach `/srv/ssd-buffer/services/vaultwarden/backup/`. Wird nachts auf ZFS synchronisiert und per Offsite-Backup gesichert.

Zusätzlich: Regelmäßig einen verschlüsselten Vault-Export machen (Web-UI → Einstellungen → Tresor exportieren).
