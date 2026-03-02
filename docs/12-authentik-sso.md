# 12 — Authentik SSO (Single Sign-On)

Einmal anmelden, überall eingeloggt. Open-Source Identity Provider.

Voraussetzung: Secrets (02), Netzwerk (03).

---

## Schritt 1: Secret Key in die Config eintragen

**Server:** In `authentik.nix` steht noch `CHANGE-ME-generate-with-openssl-rand-hex-50`. Ersetze es mit dem echten Secret.

```bash
# Den Wert aus sops lesen:
sudo cat /run/secrets/authentik-secret-key
# Oder vom Laptop:
```

**Laptop:**

```bash
sops -d ~/nixos-config/secrets/secrets.yaml | grep authentik-secret-key
```

**Server:** In **beiden** Container-Definitionen (authentik-server UND authentik-worker) ersetzen:

```bash
nano modules/server/services/authentik.nix
# AUTHENTIK_SECRET_KEY = "dein-echter-key-hier";
# An BEIDEN Stellen! (server + worker)
```

> **⚠ Häufiger Fehler:** Den Key nur in einem Container ändern. Er muss in **authentik-server** UND **authentik-worker** identisch sein!

## Schritt 2: Dienst aktivieren

**Server:**

```bash
nano modules/server/services/default.nix
# ./authentik.nix einkommentieren

sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
# Warte 2-3 Minuten (4 Container: server, worker, postgres, redis)
```

## Schritt 3: Status prüfen

**Server:**

```bash
sudo podman ps | grep authentik
# Sollte 4 Container zeigen, alle "Up"
```

Falls Container nicht starten:

```bash
sudo podman logs authentik-server 2>&1 | tail -30
```

## Schritt 4: Erster Login

1. **Laptop/Browser:** `https://auth.home.lan/if/flow/initial-setup/`
2. Admin-Account erstellen: **philip** / sicheres Passwort

> **⚠ Die Initial-Setup-URL funktioniert nur beim allerersten Aufruf!** Danach ist sie deaktiviert.

## Dienste anbinden

Für jeden Dienst erstellst du in Authentik einen **Provider** (OIDC/OAuth2) und eine **Application**.

### Nextcloud

1. **In Authentik:** Applications → Providers → Create (OAuth2/OIDC, Name: `nextcloud`)
   - Redirect URI: `https://nextcloud.home.lan/apps/sociallogin/custom_oidc/authentik`
   - Notiere Client-ID + Client-Secret

2. **In Nextcloud:** App "Social Login" installieren → Verwaltung → Social Login → Custom OpenID Connect:
   - Authorize URL: `https://auth.home.lan/application/o/authorize/`
   - Token URL: `https://auth.home.lan/application/o/token/`
   - Client ID + Secret eintragen

### Forgejo

**Server:** In `modules/server/services/forgejo.nix` den vorbereiteten `oauth2`-Block einkommentieren.

### Immich

Administration → OAuth → Issuer URL: `https://auth.home.lan/application/o/immich/`

### PaperlessNGX / Netdata (Proxy-Auth)

**Server:** In `modules/server/networking/caddy.nix` sind vorbereitete `forward_auth`-Blöcke zum Einkommentieren.

## Zwei-Faktor-Authentifizierung

Authentik unterstützt TOTP und WebAuthn. Benutzer richten 2FA unter ihrem Profil ein.

## Fehlerbehebung

**"Bad Gateway":**

**Server:**
```bash
sudo podman logs authentik-server 2>&1 | tail -30
# Häufig: PostgreSQL noch nicht bereit → 1-2 Minuten warten
```

**Redirect-Loop:** Redirect-URI in Authentik muss EXAKT mit der App-Konfiguration übereinstimmen.
