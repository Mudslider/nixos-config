# ── Nix Daemon & Flakes ──────────────────────────────────────────
{ ... }:
{
  nix = {
    settings = {
      # ── Flakes aktivieren ──────────────────────────────────────
      experimental-features = [ "nix-command" "flakes" ];

      # Vertrauenswürdige Nutzer (für Remote-Builds / Caches)
      trusted-users = [ "root" "@wheel" ];

      # Automatische Store-Optimierung (Hard-Links)
      auto-optimise-store = true;
    };

    # ── Garbage Collection ───────────────────────────────────────
    gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 30d";
    };
  };
    # Accounts Deamon nicht bei jedem switch starten, sondern nur beim Systemstart
  systemd.services.accounts-daemon.restartIfChanged = false;


  # NixOS release version used for state compatibility.
  # Update this when upgrading to a new NixOS release.
  system.stateVersion = "25.05";
}
