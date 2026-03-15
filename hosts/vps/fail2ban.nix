{ config, ... }:

{
  # ── Fail2ban (SSH-Brute-Force-Schutz) ──────────────────────
  # VPS ist öffentlich erreichbar — SSH-Port-Scanning ist normal.
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;   # Wiederholungstäter: Banzeit verdoppelt sich
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # Max. 1 Woche
    };
    jails.sshd = {
      settings = {
        enabled = true;
        port = builtins.toString (builtins.head config.services.openssh.ports);
        filter = "sshd";
        maxretry = 3;
        bantime = "1h";
      };
    };
  };
}
