# ── Hauptnutzer / Primary user ────────────────────────────────────
#
# TODO: Benutzername anpassen!
# ─────────────────────────────────────────────────────────────────
{ pkgs, ... }:
{
  users.users.polly = {
    isNormalUser = true;
    description  = "Polly";

    extraGroups = [
      "wheel"            # sudo
      "networkmanager"   # Netzwerkverwaltung
      "video"            # GPU-Zugriff
      "audio"            # Audio-Zugriff
    ];

    # Initiales Passwort – bitte nach dem ersten Login ändern
    # oder mit sops-nix ein gehashtes Passwort setzen.
    initialPassword = "changeme";
  };
}
