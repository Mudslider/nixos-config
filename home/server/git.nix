{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Philip";
        email = "philip@home.lan";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nano";
    };
    ignores = [
      ".DS_Store"
      "*.swp"
      "*~"
      ".direnv"
      "result"
    ];
  };

  programs.bash.shellAliases = {
    nrs = "cd ~/nixos-config && git fetch origin && git reset --hard origin/main && sudo nixos-rebuild switch --flake ~/nixos-config#homeserver";
  };
}
