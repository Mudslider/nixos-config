{ ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      # System
      ll = "ls -lah";
      la = "ls -la";
      ".." = "cd ..";

      # NixOS (Laptop: lokal editieren → direkt rebuilden)
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad-p15";
      nrt = "sudo nixos-rebuild test --flake ~/nixos-config#thinkpad-p15";
      nfu = "nix flake update --flake ~/nixos-config";

      # Systemd
      sc = "sudo systemctl";
      jc = "sudo journalctl";
      jcf = "sudo journalctl -f";
    };

    initExtra = ''
      # Claude Code (npm global prefix)
      export PATH="$HOME/.npm-global/bin:$PATH"

      # Prompt mit Hostname und Pfad
      PS1='\[\e[1;35m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
    '';
  };
}
