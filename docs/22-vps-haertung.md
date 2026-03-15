# VPS-Härtung (15. März 2025)

## Übersicht

Der VPS (157.90.239.236) ist der öffentliche Eingangsknoten für alle `*.philipjonasch.de`-Domains.
Er terminiert TLS (Let's Encrypt) und leitet Traffic via NetBird-Tunnel an den Homeserver weiter.

Da der VPS direkt am Internet hängt, gelten strengere Sicherheitsanforderungen als für den Homeserver.

## Umgesetzte Härtungen

### 1. SSH auf Port 2222

Standard-Port 22 entfernt. Eliminiert ~99% der automatisierten Brute-Force-Scans.

```bash
# Verbindung vom Laptop:
ssh vps                  # nutzt ~/.ssh/config (Port 2222 hinterlegt)
ssh -p 2222 root@157.90.239.236  # manuell
```

**Betrifft auch:**
- `home/laptop/ssh.nix` — SSH-Alias `vps` und `homeserver-via-vps` auf Port 2222 angepasst
- `hosts/vps/firewall.nix` — Port 2222 statt 22 freigegeben
- `hosts/vps/fail2ban.nix` — Port dynamisch aus openssh.ports gelesen

### 2. SSH-Härtung

| Einstellung | Wert | Zweck |
|-------------|------|-------|
| `PasswordAuthentication` | `false` | Nur Key-Auth |
| `PermitRootLogin` | `prohibit-password` | Root nur mit Key (nötig für `nixos-rebuild --target-host`) |
| `MaxAuthTries` | `3` | Weniger Versuche pro Verbindung |
| `LoginGraceTime` | `30` | Timeout für Auth auf 30 Sekunden |

### 3. Security-Headers auf Caddy

Alle öffentlichen Hosts bekommen via Snippet `(security-headers)`:

| Header | Wert | Schutz gegen |
|--------|------|--------------|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` | HTTPS-Downgrade |
| `X-Content-Type-Options` | `nosniff` | MIME-Sniffing |
| `X-Frame-Options` | `DENY` | Clickjacking |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Referrer-Leaking |
| `-Server` | (entfernt) | Software-Fingerprinting |

### 4. Automatische Updates

```nix
system.autoUpgrade = {
  enable = true;
  flake = "github:Mudslider/nixos-config#vps";
  dates = "04:30";
  allowReboot = false;
};
```

Der VPS zieht täglich um 04:30 das aktuelle Flake von GitHub und rebuildet sich selbst.
So bekommt er Security-Patches ohne manuelles Eingreifen.

- **Kein automatischer Reboot** — nur Config-Switch
- Workflow: Laptop → ändern → pushen → VPS zieht nächste Nacht automatisch
- Dringend: manuell `nixos-rebuild switch --flake .#vps --target-host root@157.90.239.236 --build-host localhost`

### 5. Fail2ban mit eskalierenden Banzeiten

Bereits vorhanden, Fail2ban-Port jetzt dynamisch an SSH-Port gekoppelt:

```nix
port = builtins.toString (builtins.head config.services.openssh.ports);
```

Banzeiten: 1h → 2h → 4h → ... → max 168h (1 Woche) für Wiederholungstäter.

## Nicht umgesetzt (mit Begründung)

### Rate-Limiting auf Caddy
Caddy's `rate_limit`-Directive braucht ein externes Plugin, das in nixpkgs nicht enthalten ist.
Alternativen:
- `fail2ban` für Caddy-Logs (HTTP 4xx-Flooding)
- Cloudflare vorschalten (kostenloser DDoS-Schutz)
- Caddy mit Custom-Build kompilieren (`xcaddy build --with github.com/mholt/caddy-ratelimit`)

Aktuell nicht nötig — der VPS proxied nur, Dienste laufen auf dem Homeserver.

## VPS-Rebuild vom Laptop

```bash
# ACHTUNG: SSH-Port ist 2222, nicht 22!
# Die SSH-Config in home/laptop/ssh.nix hat den Port bereits hinterlegt.
# nixos-rebuild nutzt aber NICHT die SSH-Config, sondern braucht den Port explizit:

NIX_SSHOPTS="-p 2222" nixos-rebuild switch \
  --flake .#vps \
  --target-host root@157.90.239.236 \
  --build-host localhost
```

## Erstmaliges Deployment nach Härtung

**WICHTIG:** Der SSH-Port ändert sich von 22 auf 2222. Reihenfolge beachten:

1. Vom Laptop deployen (noch auf Port 22):
   ```bash
   nixos-rebuild switch --flake .#vps --target-host root@157.90.239.236 --build-host localhost
   ```
2. Ab sofort ist Port 22 geschlossen, Port 2222 offen
3. Laptop-SSH-Config wird beim nächsten `nrs` auf dem Laptop aktualisiert
4. Testen: `ssh -p 2222 root@157.90.239.236`
