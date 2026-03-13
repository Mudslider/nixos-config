{ ... }:

{
  # ── Fail2ban (SSH-Brute-Force-Schutz) ──────────────────────
  # VPS ist öffentlich erreichbar — SSH-Port-Scanning ist normal.
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;   # Wiederholungstäter: Banzeit verdoppelt sich
      multiplier = "2";
      maxtime = "168h"; # Max. 1 Woche
    };
    jails.sshd = {
      settings = {
        enabled = true;
        port = "ssh";
        filter = "sshd";
        maxretry = 3;
        bantime = "1h";
      };
    };
  };
}
