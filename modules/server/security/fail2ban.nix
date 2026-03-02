{ ... }:

{
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "48h";
      factor = "4";
    };

    jails = {
      sshd = {
        settings = {
          filter = "sshd[mode=aggressive]";
          maxretry = 3;
          findtime = "10m";
        };
      };
    };
  };
}
