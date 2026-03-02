# Disko-Konfiguration: Automatisches Partitionslayout
# NUR für die NVMe SSD (OS + Buffer). ZFS-Pool auf HDDs wird separat erstellt.
#
# Layout:
#   /dev/nvme0n1p1  512M  EFI System Partition (FAT32)
#   /dev/nvme0n1p2  Rest  ext4 Root-Partition

{ ... }:

{
  disko.devices = {
    disk = {
      nvme = {
        type = "disk";
        # TODO: Ersetze mit deinem tatsächlichen NVMe-Pfad
        # Finde ihn mit: ls -la /dev/disk/by-id/ | grep nvme
        device = "/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S649NU0W402228A";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "noatime" "discard" ];
              };
            };
          };
        };
      };
    };
  };
}
