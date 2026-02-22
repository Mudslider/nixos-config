# ╭──────────────────────────────────────────────────────────────────╮
# │  Dendritic root – imports every branch automatically.           │
# │  Add a new directory here and it will be picked up.             │
# ╰──────────────────────────────────────────────────────────────────╯
{ ... }:
{
  imports = [
    ./hardware
    ./desktop
    ./networking
    ./locale
    ./programs
    ./services
    ./security
    ./system
    ./users
  ];
}
