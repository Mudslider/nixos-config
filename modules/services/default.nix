# ── services branch ──────────────────────────────────────────────
{ ... }:
{
  imports = [
    ./pipewire.nix
    ./printing.nix
    ./vaultwarden.nix
    ./openssh.nix
  ];
}
