# ── Intel CPU (i9) – microcode & thermals ────────────────────────
{ pkgs, ... }:
{
  hardware.cpu.intel.updateMicrocode = true;

  # Enable thermald for Intel thermal management (ThinkPad P15)
  services.thermald.enable = true;
}
