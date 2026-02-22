# ── sops-nix – verschlüsselte Secrets ────────────────────────────
#
# Workflow:
# 1. age-Schlüssel erzeugen:
#      mkdir -p ~/.config/sops/age
#      age-keygen -o ~/.config/sops/age/keys.txt
#
# 2. Public-Key aus der Datei ablesen und in .sops.yaml eintragen.
#
# 3. secrets/secrets.yaml anlegen und verschlüsseln:
#      sops secrets/secrets.yaml
#
# 4. In diesem Modul die gewünschten Secrets referenzieren.
#
# Siehe README.md für eine ausführliche Anleitung.
# ─────────────────────────────────────────────────────────────────
{ config, ... }:
{
  sops = {
    # Pfad zum verschlüsselten Secrets-File (relativ zum Flake-Root)
    defaultSopsFile = ../../secrets/secrets.yaml;

    # age als Verschlüsselungs-Backend
    age = {
      # Schlüsseldatei auf dem Zielsystem
      keyFile = "/var/lib/sops-nix/key.txt";

      # Schlüssel beim ersten Aktivieren automatisch erzeugen
      generateKey = true;
    };

    # ── Beispiel-Secrets ─────────────────────────────────────────
    # Auskommentieren und anpassen, sobald secrets/secrets.yaml
    # vorhanden ist.
    #
    # secrets."vaultwarden/admin_token" = {
    #   owner = "vaultwarden";
    # };
    # secrets."user/password" = {
    #   neededForUsers = true;
    # };
  };
}
