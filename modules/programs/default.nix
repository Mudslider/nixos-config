# ── programs branch ──────────────────────────────────────────────
{ ... }:
{
  imports = [
    ./firefox.nix
    ./chromium.nix
    ./neovim.nix
    ./packages.nix
    ./stow.nix
  ];
}
