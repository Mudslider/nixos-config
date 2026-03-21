#!/bin/bash
set -euo pipefail

# ── Restic Backup Setup: Noras Laptop → Homeserver ──────────
#
# Einmalig als root ausführen:
#   chmod +x setup-backup-nora.sh && sudo ./setup-backup-nora.sh
#
# Voraussetzungen:
#   - Laptop im Heimnetz (192.168.178.x)
#   - htpasswd-Eintrag "nora" auf dem Server existiert
#   - Repo-Unterverzeichnis /srv/ssd-buffer/backup/nora/ existiert

SERVER_IP="192.168.178.10"
SERVER_PORT="8100"
REPO_NAME="nora"
BACKUP_USER="$(logname)"
BACKUP_PATH="/home/$BACKUP_USER"

echo "=== Restic Backup Setup ==="
echo "Server:      $SERVER_IP:$SERVER_PORT"
echo "Repo:        $REPO_NAME"
echo "Backup-Pfad: $BACKUP_PATH"
echo "User:        $BACKUP_USER"
echo ""

# ── 1. Restic installieren ─────────────────────────────────
if ! command -v restic &>/dev/null; then
  echo "Installiere restic..."
  apt-get update && apt-get install -y restic
else
  echo "restic bereits installiert: $(restic version)"
fi

# ── 2. Credentials abfragen ────────────────────────────────
echo ""
echo "Zwei Passwörter werden benötigt:"
echo "  1) HTTP-Auth Passwort   = Zugang zum REST-Server (htpasswd)"
echo "  2) Repo-Passwort        = Verschlüsselung der Backups"
echo ""
read -rp  "HTTP-Auth Passwort für User '$REPO_NAME': " HTTP_PASS
read -rsp "Repo-Verschlüsselungspasswort: " REPO_PASS
echo ""

# ── 3. Credential-Dateien anlegen ──────────────────────────
mkdir -p /etc/restic
echo "rest:http://${REPO_NAME}:${HTTP_PASS}@${SERVER_IP}:${SERVER_PORT}/${REPO_NAME}/" > /etc/restic/repository
echo "$REPO_PASS" > /etc/restic/password
chmod 600 /etc/restic/repository /etc/restic/password
echo "Credentials gespeichert in /etc/restic/"

# ── 4. Verbindung testen + Repo initialisieren ─────────────
echo ""
echo "Teste Verbindung zum Server..."
export RESTIC_REPOSITORY_FILE=/etc/restic/repository
export RESTIC_PASSWORD_FILE=/etc/restic/password

if restic cat config &>/dev/null 2>&1; then
  echo "Repo existiert bereits — kein Init nötig."
else
  echo "Initialisiere neues Repo..."
  restic init
fi
echo "Verbindung OK."

# ── 5. Systemd-Service anlegen ─────────────────────────────
cat > /etc/systemd/system/restic-backup.service << EOF
[Unit]
Description=Restic Backup nach Homeserver
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
Environment="RESTIC_REPOSITORY_FILE=/etc/restic/repository"
Environment="RESTIC_PASSWORD_FILE=/etc/restic/password"
ExecStart=$(command -v restic) backup \\
  --verbose \\
  --exclude-caches \\
  --exclude '/home/*/.cache' \\
  --exclude '/home/*/.local/share/Trash' \\
  --exclude '/home/*/.mozilla/firefox/*/storage' \\
  --exclude '/home/*/.thunderbird/*/ImapMail' \\
  --exclude 'node_modules' \\
  --exclude '__pycache__' \\
  --exclude '*.tmp' \\
  --exclude '.git/objects' \\
  ${BACKUP_PATH}
EOF

# ── 6. Systemd-Timer anlegen ──────────────────────────────
cat > /etc/systemd/system/restic-backup.timer << 'EOF'
[Unit]
Description=Tägliches Restic Backup

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=30m

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now restic-backup.timer

# ── 7. Erstes Test-Backup ─────────────────────────────────
echo ""
read -rp "Jetzt ein erstes Test-Backup starten? (j/n) " FIRST_BACKUP
if [[ "$FIRST_BACKUP" == "j" ]]; then
  echo "Starte Backup... (kann einige Minuten dauern)"
  systemctl start restic-backup.service
  echo "Fertig! Überprüfe mit: sudo restic -r \"\$(cat /etc/restic/repository)\" --password-file /etc/restic/password snapshots"
fi

echo ""
echo "=== Setup abgeschlossen ==="
echo ""
echo "Nützliche Befehle:"
echo "  Status:    systemctl status restic-backup.timer"
echo "  Manuell:   sudo systemctl start restic-backup.service"
echo "  Logs:      journalctl -u restic-backup.service"
echo "  Snapshots: sudo restic -r \"\$(cat /etc/restic/repository)\" --password-file /etc/restic/password snapshots"
