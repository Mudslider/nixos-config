# ╭──────────────────────────────────────────────────────────────────╮
# │  hardware-configuration.nix                                      │
# │                                                                  │
# │  DIESE DATEI WIRD AUTOMATISCH ERZEUGT – nicht manuell ändern!    │
# │                                                                  │
# │  Führe auf dem Zielsystem aus:                                   │
# │    sudo nixos-generate-config --show-hardware-config             │
# │  und ersetze diesen Platzhalter durch die Ausgabe. -ERLEDIGT-    │
# ╰──────────────────────────────────────────────────────────────────╯
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # ── Kernel-Module (Beispielwerte sind durch alte hardware-config ersetzt) ──────────────────
   boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "uas" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/luks-c011d5ac-791b-4da6-9a6c-16c7fae4ff40";
      fsType = "ext4";
    };

   boot.initrd.luks.devices."luks-c011d5ac-791b-4da6-9a6c-16c7fae4ff40" = {
    device = "/dev/disk/by-uuid/c011d5ac-791b-4da6-9a6c-16c7fae4ff40";
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  # ── Dateisysteme (Beispielwerte sind durch alte hardware-config ersetzt) ───────────────────
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/5993-504A";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/mapper/luks-6f73df94-90ca-4911-978c-92cf8a6f362a"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
