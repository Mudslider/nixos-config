# ── Chromium ─────────────────────────────────────────────────────
{ pkgs, ... }:
{
  # Installed as a system package; unfree already allowed via nvidia.nix.
  environment.systemPackages = [ pkgs.chromium ];
}
