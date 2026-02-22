# ── NVIDIA RTX A4000 (8 GB VRAM) ─────────────────────────────────
#
# The ThinkPad P15 uses NVIDIA Optimus (Intel iGPU + NVIDIA dGPU).
# We use the "offload" PRIME mode so the Intel GPU handles the
# display and the NVIDIA card is available on-demand.
# To run an application on the NVIDIA GPU:
#   nvidia-offload <command>
# ─────────────────────────────────────────────────────────────────
{ config, pkgs, lib, ... }:
{
  # ── Allow unfree NVIDIA driver ─────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ── Load the NVIDIA kernel module ──────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Use the production (stable) driver branch.
    # Change to "beta" if you need newer features.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is required for Wayland compositors (KWin)
    modesetting.enable = true;

    # Power-management – experimental; enable if you see
    # suspend/resume issues.  Safe to leave off initially.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Disable the open-source kernel module (not yet on par with
    # the proprietary one for Turing/Ampere workstation GPUs).
    open = false;

    # Enable the nvidia-settings GUI
    nvidiaSettings = true;

    # ── PRIME offload (Intel + NVIDIA) ───────────────────────────
    #
    # Bus IDs – verify yours with:
    #   lspci | grep -E '(VGA|3D)'
    # and convert hex → decimal (e.g. 01:00.0 → PCI:1:0:0).
    #
    # The values below are the *typical* ThinkPad P15 IDs.
    # Adjust if lspci shows different addresses.
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;   # provides `nvidia-offload` wrapper
      };
      intelBusId  = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # ── OpenGL / Vulkan ────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;           # needed for Steam / Wine / 32-bit GL
  };
}
