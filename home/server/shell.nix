{ ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      # System
      ll = "ls -lah";
      la = "ls -la";
      ".." = "cd ..";

      # NixOS
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config#homeserver";
      nrt = "sudo nixos-rebuild test --flake ~/nixos-config#homeserver";
      nfu = "nix flake update ~/nixos-config";

      # Systemd
      sc = "sudo systemctl";
      jc = "sudo journalctl";
      jcf = "sudo journalctl -f";

      # ZFS
      zl = "sudo zfs list";
      zs = "sudo zfs list -t snapshot";
      zpool-status = "sudo zpool status";

      # Podman
      pd = "sudo podman";
      pds = "sudo podman ps -a";
      pdl = "sudo podman logs -f";

      # HDD-Status prüfen
      hdd-status = "sudo hdparm -C /dev/disk/by-id/ata-WDC_WD*";
    };

    initExtra = ''
      # Prompt mit Hostname und Pfad
      PS1='\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
    '';
  };
}
