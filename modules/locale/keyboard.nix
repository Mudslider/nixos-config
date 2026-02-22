# ── Tastaturlayout / Keyboard ────────────────────────────────────
{ ... }:
{
  # X11 / Wayland keyboard
  services.xserver.xkb = {
    layout  = "de";
    variant = "";
  };

  # Virtual-console (TTY) keyboard
  console.keyMap = "de";
}
