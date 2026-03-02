# ACHTUNG: Diese Datei wird während der Installation automatisch generiert.
# Führe auf dem Server aus:
#   nixos-generate-config --no-filesystems --show-hardware-config --root /mnt
# und ersetze diese Datei mit dem Output.
#
# Die nachfolgende Konfiguration ist ein Platzhalter für das ASRock N100DC-ITX.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Intel N100 Firmware
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}
