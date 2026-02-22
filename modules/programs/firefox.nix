# ── Firefox + Add-ons (uBlock Origin, Privacy Badger) ────────────
#
# Extensions are installed system-wide via Mozilla Enterprise
# Policies so they are active in every profile and session,
# including private windows.
# ─────────────────────────────────────────────────────────────────
{ pkgs, ... }:
{
  programs.firefox = {
    enable = true;

    # ── Enterprise Policies ──────────────────────────────────────
    # Ref: https://mozilla.github.io/policy-templates/
    policies = {
      # Disable first-run telemetry & data collection
      DisableTelemetry    = true;
      DisableFirefoxStudies = true;
      DisablePocket       = true;

      # Do-Not-Track header
      EnableTrackingProtection = {
        Value          = true;
        Locked         = true;
        Cryptomining   = true;
        Fingerprinting = true;
      };

      # ── Extension installation ─────────────────────────────────
      # "Install" = always installed; "locked" = user can't remove.
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url    = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        # Privacy Badger
        "jid1-MnnxcxisBPnSXQ@jetpack" = {
          install_url    = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi";
          installation_mode = "force_installed";
        };
         # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url       = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
};
      };

      # Allow extensions in private windows
      ExtensionSettings."*".private_browsing = "allowed";
    };
  };
}
