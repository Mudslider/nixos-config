{ ... }:

{
  # ── ntfy (Push-Benachrichtigungen) ────────────────────────
  # Leichtgewichtiger Pub/Sub-Benachrichtigungsdienst.
  # App: iOS/Android "ntfy", Topics frei wählbar.

  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.home.lan";
      listen-http = ":8084";
      # Standardmäßig offen im LAN — kein Auth nötig für Heimnetz
      # auth-default-access = "deny-all";  # Aktivieren für Auth
    };
  };
}
