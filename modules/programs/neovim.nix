# ── Neovim ───────────────────────────────────────────────────────
{ pkgs, ... }:
{
  programs.neovim = {
    enable        = true;
    defaultEditor = true;          # $EDITOR=nvim
    viAlias       = true;
    vimAlias      = true;
  };
}
