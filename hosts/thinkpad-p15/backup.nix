{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.restic ];
  # ── Restic Laptop-Backup → Homeserver ──────────────────────
  # Täglich, Persistent (wird nachgeholt wenn Laptop aus war).
  #
  # Einmalig einrichten:
  #   Server:
  #     sudo htpasswd -B /srv/ssd-buffer/backup/.htpasswd polly
  #   Laptop (nach nrs):
  #     sudo bash -c 'echo "rest:http://USER:DEIN_HTTP_PASS@100.95.103.67:8100/polly" > /etc/restic/repository && chmod 600 /etc/restic/repository'
  #     sudo bash -c 'read -rsp "Repo-Passwort: " p && echo "$p" > /etc/restic/password && chmod 600 /etc/restic/password'
  #     sudo restic -r /etc/restic/repository --password-file /etc/restic/password init

  services.restic.backups.laptop = {
    repositoryFile = "/etc/restic/repository";  # enthält volle URL inkl. HTTP-Auth
    passwordFile   = "/etc/restic/password";    # Restic-Verschlüsselungspasswort

    paths = [ "/home/polly" ];
    # Enthält u.a.: ~/.knowledge-base/kb.db, ~/obsidian-vaults/claude-kb/

    exclude = [
      "/home/polly/.cache"
      "/home/polly/.local/share/Trash"
      "/home/polly/.local/share/Steam"
      "/home/polly/.mozilla/firefox/*/storage"
      "node_modules"
      ".git/objects"
      "__pycache__"
      "*.pyc"
      "*.tmp"
      "result"        # nix build symlinks
    ];

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 10"
    ];

    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;  # Backup nachholen wenn Laptop ausgeschaltet war
    };
  };

  # Verzeichnis für Credential-Dateien (werden manuell befüllt)
  systemd.tmpfiles.rules = [
    "d /etc/restic 0700 root root -"
  ];
}
