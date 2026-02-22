# ── hardware branch ──────────────────────────────────────────────
{ ... }:
{
  imports = [
    ./cpu.nix
    ./nvidia.nix
    ./bluetooth.nix
    ./firmware.nix
  ];
}
