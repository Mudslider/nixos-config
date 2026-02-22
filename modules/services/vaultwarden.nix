# ── Vaultwarden (self-hosted Bitwarden-kompatibel) ───────────────
#
# Läuft lokal auf Port 8000.  Zugriff über:
#   http://localhost:8000
#
# Für Zugriff von anderen Geräten im Netz die Firewall-Ports
# in networking/firewall.nix öffnen und DOMAIN anpassen.
# ─────────────────────────────────────────────────────────────────
{ ... }:
{
  services.vaultwarden = {
    enable = true;

    config = {
      DOMAIN              = "http://localhost:8000";
      SIGNUPS_ALLOWED     = true;     # false setzen nach Erstregistrierung
      ROCKET_ADDRESS      = "127.0.0.1";
      ROCKET_PORT         = 8000;
      ROCKET_LOG          = "normal";
    };
  };
}
