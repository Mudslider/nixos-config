{ ... }:

{
  # ── Disk-Konfiguration (Hetzner CX23, BIOS-Boot) ──────────
  disko.devices = {
    disk.vda = {
      type = "disk";
      device = "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1M";
            type = "EF02";  # BIOS boot partition (kein EFI auf Hetzner KVM)
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
