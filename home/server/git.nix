{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Philip";
    userEmail = "philip@home.lan";

    extraConfig = {
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
}
