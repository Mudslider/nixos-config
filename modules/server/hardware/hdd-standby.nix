{ pkgs, ... }:

{
  # ── HDD-Standby nach Inaktivität ─────────────────────────
  # Die WD Red Plus HDDs sollen nur laufen, wenn auf sie zugegriffen wird.
  # hdparm -S 120 = 120 × 5 Sekunden = 10 Minuten bis Standby
  # hdparm -B 127 = APM-Level: aggressives Standby erlaubt

  systemd.services.hdd-standby = {
    description = "HDD Standby-Timer konfigurieren";
    after = [ "local-fs.target" "zfs-mount.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "set-hdd-standby" ''
        # Warte kurz, bis alle Geräte initialisiert sind
        sleep 10

        # Finde WD Red Plus HDDs und setze Standby-Timer
        for disk in /dev/disk/by-id/ata-WDC_WD*; do
          if [ -b "$disk" ]; then
            echo "Setze Standby für $disk"
            ${pkgs.hdparm}/bin/hdparm -S 120 -B 127 "$disk" || true
          fi
        done
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    hdparm
  ];
}
