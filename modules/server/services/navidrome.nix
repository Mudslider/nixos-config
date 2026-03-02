{ ... }:

{
  # ── Navidrome ─────────────────────────────────────────────
  # Musik-Streaming-Server (Subsonic-kompatibel)

  services.navidrome = {
    enable = true;
    settings = {
      Address = "127.0.0.1";
      Port = 4533;
      MusicFolder = "/tank/media/musik";
      DataFolder = "/srv/ssd-buffer/services/navidrome";
      ScanSchedule = "@every 1h";
      TranscodingCacheSize = "500MB";
      DefaultLanguage = "de";
    };
  };
}
