#!/usr/bin/env bash
# ── Update-Checker ────────────────────────────────────────────
# Zeigt verfügbare Updates für Nix-Inputs und Container-Images.
# Aufruf: ./scripts/check-updates.sh

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BOLD}═══ Homeserver Update-Check ═══${NC}"
echo ""

# ── 1. Nix Flake-Inputs ─────────────────────────────────────
echo -e "${BOLD}[1] Nix Flake-Inputs${NC}"
echo "    Prüfe verfügbare Updates..."
nix flake update --dry-run 2>&1 | grep -E "Updated|locked|•" | sed 's/^/    /' || true
echo ""

# ── 2. Container-Images ──────────────────────────────────────
echo -e "${BOLD}[2] Container-Images${NC}"

check_github() {
  local repo="$1" current="$2" name="$3"
  latest=$(curl -sf "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name // empty')
  if [ -z "$latest" ]; then
    echo -e "    ${YELLOW}?${NC} ${name}: Konnte nicht prüfen"
  elif [ "$current" = "$latest" ]; then
    echo -e "    ${GREEN}✓${NC} ${name}: ${current} (aktuell)"
  else
    echo -e "    ${RED}↑${NC} ${name}: ${current} → ${latest}"
  fi
}

# Versionen aus den Nix-Dateien lesen
IMMICH_CURRENT=$(grep 'immich-server:v' "$(dirname "$0")/../modules/server/services/immich.nix" | grep -o 'v[0-9][0-9.]*' | head -1)
UPTIME_CURRENT=$(grep 'uptime-kuma:' "$(dirname "$0")/../modules/server/services/uptime-kuma.nix" | grep -o '[0-9][0-9.]*' | head -1)

check_github "immich-app/immich"          "${IMMICH_CURRENT}"   "Immich"
check_github "louislam/uptime-kuma"       "${UPTIME_CURRENT}"   "Uptime Kuma"

echo ""
echo -e "${BOLD}Update-Workflow:${NC}"
echo "  1. nix flake update ~/nixos-config    # Nix-Inputs aktualisieren"
echo "  2. Container-Versionen in .nix-Dateien anpassen (falls Updates)"
echo "  3. nrt && nrs                          # Laptop testen + switchen"
echo "  4. git add -A && git commit && git push"
echo "  5. Server: nrs"
echo ""

# ── Heartbeat an Uptime Kuma senden ──────────────────────────
# Bestätigt dass der monatliche Update-Check durchgeführt wurde.
# Kommt 30 Tage kein Heartbeat → Benachrichtigung von Uptime Kuma.
PUSH_URL="https://status.home.lan/api/push/jNiAW2BYdm?status=up&msg=OK&ping="
if curl -sf --cacert /etc/ssl/certs/ca-bundle.crt "${PUSH_URL}" > /dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} Heartbeat an Uptime Kuma gesendet"
else
  echo -e "${YELLOW}!${NC} Heartbeat konnte nicht gesendet werden (Server erreichbar?)"
fi
