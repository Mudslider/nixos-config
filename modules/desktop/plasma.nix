# ── KDE Plasma 6 (Wayland) ───────────────────────────────────────
#
# Mirrors the packages shipped by the NixOS graphical installer
# (unstable channel, Plasma edition).
# ─────────────────────────────────────────────────────────────────
{ pkgs, ... }:
{
  # ── Display manager ────────────────────────────────────────────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # ── Plasma Desktop ────────────────────────────────────────────
  services.desktopManager.plasma6.enable = true;

  # ── X11 fallback (for apps that need it) ───────────────────────
  services.xserver.enable = true;
}
