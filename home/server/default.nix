{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./tools.nix
  ];

  home = {
    username = "philip";
    homeDirectory = "/home/philip";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
