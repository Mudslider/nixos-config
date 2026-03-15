{ ... }:

{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      # Homeserver direkt über NetBird (primär)
      "homeserver" = {
        hostname = "100.95.103.67";
        user = "philip";
      };

      # Homeserver über VPS als Sprunghost (Fallback wenn NetBird nicht verfügbar)
      "homeserver-via-vps" = {
        hostname = "100.95.103.67";
        user = "philip";
        proxyJump = "root@157.90.239.236";
      };

      # VPS direkt
      "vps" = {
        hostname = "157.90.239.236";
        user = "root";
      };
    };
  };
}
