# ── networking branch ─────────────────────────────────────────────
{ ... }:
{
  imports = [
    ./networkmanager.nix
    ./firewall.nix
  ];
}
