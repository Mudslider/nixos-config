{ pkgs, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./tools.nix
    ./ssh.nix
  ];

  home = {
    username = "polly";
    homeDirectory = "/home/polly";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
