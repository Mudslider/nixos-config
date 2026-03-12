# ── Git-Konfiguration (beide Maschinen) ─────────────────────
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
}
