{ inputs, pkgs, ... }:

{
  # ── AutoASPM ──────────────────────────────────────────────
  # Aktiviert Active State Power Management für alle PCI-Express-Geräte
  services.autoaspm.enable = true;

  # ── Kernel-Parameter für maximale Energieeffizienz ────────
  boot.kernelParams = [
    # Intel P-State: passive Mode für bessere Governor-Kontrolle
    "intel_pstate=passive"

    # Erlaube tiefste C-States (C6/C7/C8/C10)
    "processor.max_cstate=9"
    "intel_idle.max_cstate=9"

    # ASPM erzwingen (falls BIOS es nicht aktiviert)
    "pcie_aspm=force"
    "pcie_aspm.policy=powersupersave"

    # ZFS ARC-Limit: 8 GB (Rest für Dienste)
    "zfs.zfs_arc_max=8589934592"
  ];

  # ── powertop Auto-Tune ────────────────────────────────────
  powerManagement.powertop.enable = true;

  # ── CPU-Governor ──────────────────────────────────────────
  powerManagement.cpuFreqGovernor = "schedutil";

  # ── Intel Thermald ────────────────────────────────────────
  services.thermald.enable = true;

  # ── Intel GPU (für Jellyfin Hardware-Transcoding) ─────────
  hardware.graphics.enable = true;
}
