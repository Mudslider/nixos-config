{ config, pkgs, ... }:

{
  # ── ZFS Kernel-Support ────────────────────────────────────
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;

  # ── ZFS Services ──────────────────────────────────────────

  # Automatischer Import des Pools beim Boot
  # TEMPORÄR DEAKTIVIERT — erst nach Anleitung 01 einkommentieren
# boot.zfs.extraPools = [ "tank" ];

  # Wöchentlicher Scrub: prüft alle Blöcke auf Bitrot
  services.zfs.autoScrub = {
    enable = true;
    interval = "Sun, 04:00";
    pools = [ "tank" ];
  };

  # Automatisches Trimmen (für SSD-basierte Pools, hier nicht nötig,
  # aber schadet nicht als Vorbereitung)
  services.zfs.trim = {
    enable = true;
    interval = "weekly";
  };

  # ── ZFS-Snapshot-Automatisierung ──────────────────────────
  # Stündliche Snapshots des wichtigsten Datasets, Retention: 48h

  # TEMPORÄR DEAKTIVIERT — erst nach Anleitung 01 einkommentieren
  # services.sanoid = {
  #   enable = true;
  #   datasets = {
  #     "tank/backup" = {
  #       hourly = 48;
  #       daily = 30;
  #       monthly = 6;
  #       autosnap = true;
  #       autoprune = true;
  #     };
  #     "tank/documents" = {
  #       hourly = 24;
  #       daily = 30;
  #       monthly = 6;
  #       autosnap = true;
  #       autoprune = true;
  #     };
  #     "tank/photos" = {
  #       daily = 30;
  #       monthly = 12;
  #       autosnap = true;
  #       autoprune = true;
  #     };
  #     "tank/media" = {
  #       daily = 7;
  #       monthly = 3;
  #       autosnap = true;
  #       autoprune = true;
  #     };
  #   };
  # };

  # ── SMART-Monitoring ──────────────────────────────────────
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications = {
      mail.enable = false;
      wall.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    zfs
    sanoid
    smartmontools
    lsof
  ];

  # ── Automatischer ZFS-Unlock (Optional) ───────────────────
  # Standard: Manueller Unlock per SSH nach jedem Reboot.
  # Falls du ein Keyfile auf der SSD nutzen willst (bequemer,
  # schützt aber nur gegen HDD-Diebstahl ohne SSD):
  #
  # 1. Keyfile erstellen:
  #    sudo dd if=/dev/urandom of=/root/.zfs-keyfile bs=32 count=1
  #    sudo chmod 600 /root/.zfs-keyfile
  # 2. Pool umstellen:
  #    sudo zfs change-key -o keyformat=raw -o keylocation=file:///root/.zfs-keyfile tank
  # 3. Diesen Block einkommentieren:
  #
  # Siehe Anleitung 01-zfs-setup.md
  #
  # systemd.services.zfs-load-key = {
  #   description = "Load ZFS encryption key from keyfile";
  #   after = [ "zfs-import.target" ];
  #   before = [ "zfs-mount.service" ];
  #   wantedBy = [ "zfs-mount.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.zfs}/bin/zfs load-key tank";
  #   };
  # };
}
