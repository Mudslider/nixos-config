# ── Firmware updates (fwupd) & non-free firmware blobs ───────────
{ pkgs, ... }:
{
  # Enable Linux firmware blobs (WiFi, etc.)
  hardware.enableRedistributableFirmware = true;

  # Firmware update daemon (LVFS) – `fwupdmgr update`
  services.fwupd.enable = true;
}
