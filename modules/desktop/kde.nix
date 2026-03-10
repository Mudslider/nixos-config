# ── KDE Plasma 6 + Tastatur ─────────────────────────────────
{ ... }:
{
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Tastatur-Layout (Desktop-spezifisch, ergänzt console.keyMap aus locale.nix)
  services.xserver.xkb.layout = "de";
  services.xserver.xkb.variant = "";
}
