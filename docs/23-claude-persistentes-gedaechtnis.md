# Claude Code — Persistentes Gedächtnis mit Knowledge Base Server

## Motivation

Claude Code hat ein eingebautes Memory-System (`.claude/projects/*/memory/`), aber:
- Erinnerungen sind flach (Markdown-Dateien), keine Volltextsuche
- Kein Zugriff von Claude.ai (Web) auf Claude Code Kontext und umgekehrt
- Kein Self-Learning: Erkenntnisse aus Sessions werden nicht automatisch destilliert
- Kein Session-Capture: Debugging-Sessions, Fixes und Patterns gehen verloren

**Ziel:** Ein MCP-basierter Knowledge Base Server auf dem Homeserver, der Claude Code
persistentes, durchsuchbares Wissen gibt — mit Self-Learning-Loop.

## Konzept (basierend auf willynikes2/knowledge-base-server)

```
Obsidian Vault (Laptop, human curation)
  → Knowledge Base Server (Homeserver, SQLite FTS5)
    → MCP Interface (stdio oder HTTP)
      → Claude Code (Laptop, über MCP)
      → Claude.ai (Web, über MCP oder REST API)
```

**Kernidee:** SQLite mit FTS5 (Full-Text Search) als leichtgewichtige Wissensdatenbank.
Kein Vector-DB, kein Cloud-Dienst. Alles lokal/self-hosted.

## Architektur-Entscheidungen

### Option A: KB Server auf Homeserver (empfohlen)
- **Pro:** Immer erreichbar (über NetBird auch unterwegs), zentral, Backup via ZFS
- **Con:** Node.js-Dienst auf dem Homeserver, Latenz bei MCP-Calls über Netzwerk
- **MCP-Anbindung:** HTTP/REST über NetBird-IP, nicht stdio (stdio nur lokal möglich)

### Option B: KB Server lokal auf Laptop
- **Pro:** Schnellste MCP-Anbindung (stdio), kein Netzwerk nötig
- **Con:** Nur verfügbar wenn Laptop an, kein Zugriff von anderswo
- **MCP-Anbindung:** stdio (direkt)

### Option C: Hybrid — lokal mit Sync zum Homeserver
- **Pro:** Schnelle lokale MCP-Calls + zentrales Backup
- **Con:** Sync-Logik, Konflikte möglich

**Empfehlung:** Start mit **Option B** (lokal auf Laptop), später zu A oder C migrieren.
Grund: Einfachster Einstieg, stdio-MCP funktioniert sofort, kein Netzwerk-Debugging.

## Umsetzungsplan

### Phase 1: Grundlagen (Laptop)

#### 1.1 Node.js sicherstellen
NixOS hat kein globales npm. Zwei Wege:
```nix
# Option: In home/laptop/ als User-Paket
home.packages = with pkgs; [ nodejs_22 ];
```
Oder als `nix-shell` / `devShell` nur für den KB-Server.

#### 1.2 Knowledge Base Server installieren
```bash
cd ~
git clone https://github.com/willynikes2/knowledge-base-server.git
cd knowledge-base-server
npm install
# Kein npm link auf NixOS! Stattdessen direkt aufrufen:
node bin/kb.js setup
```

#### 1.3 Konfiguration
```bash
# .env im knowledge-base-server Verzeichnis
KB_PASSWORD=<sicheres-passwort>
KB_PORT=3838
# Obsidian Vault Pfad (oder beliebiges Markdown-Verzeichnis):
OBSIDIAN_VAULT_PATH=~/notes  # oder ~/obsidian-vault
```

#### 1.4 MCP bei Claude Code registrieren
```bash
node bin/kb.js register
# Oder manuell in ~/.claude.json:
```
```json
{
  "mcpServers": {
    "knowledge-base": {
      "command": "node",
      "args": ["/home/polly/knowledge-base-server/bin/kb.js", "mcp"]
    }
  }
}
```

#### 1.5 Erstes Ingest
```bash
# Existierende Claude-Memory-Dateien einspeisen:
node bin/kb.js ingest ~/.claude/projects/-home-polly-nixos-config/memory/

# NixOS-Config-Docs einspeisen:
node bin/kb.js ingest ~/nixos-config/docs/

# CLAUDE.md einspeisen:
node bin/kb.js ingest ~/nixos-config/CLAUDE.md
```

### Phase 2: Self-Learning einrichten

#### 2.1 Session-Capture Workflow
Nach jeder produktiven Claude-Code-Session:
- Claude nutzt `kb_capture_session` um Erkenntnisse zu speichern
- Fixes werden mit `kb_capture_fix` dokumentiert (Symptom → Ursache → Lösung)

#### 2.2 CLAUDE.md Auto-Update
In `CLAUDE.md` eine Anweisung ergänzen:
```markdown
## Self-Learning
- Am Ende jeder Session: Nutze `kb_capture_session` um wichtige Erkenntnisse zu speichern
- Bei Bug-Fixes: Nutze `kb_capture_fix` mit Symptom, Ursache und Lösung
- Vor komplexen Aufgaben: Nutze `kb_search` um frühere Sessions zu ähnlichen Themen zu finden
```

#### 2.3 Drei-Tier-Wissensmanagement
- **Hot:** Aktive Projekte, letzte Sessions (wird zuerst durchsucht)
- **Warm:** Validierte Workflows, Lessons Learned
- **Cold:** Rohe Session-Captures, Archiv

### Phase 3: Obsidian einrichten (optional)

#### 3.1 Obsidian auf NixOS
```nix
# home/laptop/packages.nix oder ähnlich
home.packages = with pkgs; [ obsidian ];
```

#### 3.2 Vault-Struktur
```
~/obsidian-vault/
  claude/          ← AI-generierte Notizen (kb_write)
  projekte/        ← Manuelle Projektnotizen
  referenzen/      ← Links, Docs, Snippets
  sessions/        ← Auto-captured Sessions
```

#### 3.3 Bidirektionaler Sync
- Obsidian schreibt → KB Server ingestet automatisch (File-Watcher)
- Claude schreibt via `kb_write` → Notiz landet im Vault
- Mensch kuratiert im Vault → bereinigtes Wissen für Claude

## Verfügbare MCP-Tools (nach Setup)

| Tool | Zweck |
|------|-------|
| `kb_search` | Volltextsuche mit BM25-Ranking |
| `kb_search_smart` | Hybrid-Suche (Keyword + Semantik) |
| `kb_context` | Token-effizientes Briefing (90% Einsparung) |
| `kb_read` | Dokument vollständig lesen |
| `kb_list` | Dokumente nach Typ/Tag filtern |
| `kb_write` | Neue Notiz in Obsidian Vault schreiben |
| `kb_ingest` | Rohtext direkt einspeisen |
| `kb_capture_session` | Debugging/Coding-Session aufzeichnen |
| `kb_capture_fix` | Bug-Fix dokumentieren (Symptom/Ursache/Lösung) |
| `kb_synthesize` | Quellen-übergreifende Erkenntnisse generieren |
| `kb_safety_check` | Destruktive Aktionen gegen KB-Historie prüfen |

## Abgrenzung zum bestehenden Memory-System

| | Claude Built-in Memory | KB Server |
|---|---|---|
| Speicher | `.claude/projects/*/memory/*.md` | SQLite FTS5 |
| Suche | Dateiname + manuelles Lesen | Volltextsuche mit Ranking |
| Zugriff | Nur Claude Code, nur dieses Projekt | Claude Code (lokal, stdio) |
| Self-Learning | Manuell (Memory-Dateien pflegen) | Automatisch (Session-Capture) |
| Kapazität | ~200 Zeilen MEMORY.md Index | Unbegrenzt (SQLite) |

**Empfehlung:** Beide parallel nutzen. Built-in Memory für schnelle Projekt-Fakten,
KB Server für tiefes, durchsuchbares Wissen über Sessions hinweg.

## Aufwand & Risiken

**Aufwand:** ~2–3 Stunden für Phase 1+2 (Laptop-Setup mit Self-Learning)

**Risiken:**
- Node.js auf NixOS: `npm install` kann Native-Module-Probleme haben → `nix-shell` mit Build-Tools
- KB Server ist Community-Projekt (ein Entwickler) → Code vor dem Einsatz prüfen
- Obsidian ist proprietär (Electron-App) → Alternative: beliebiges Markdown-Verzeichnis reicht

## Status

- **Phase 1** ✓ KB Server lokal installiert, 53 Dokumente indexiert und getaggt
- **Phase 2** ✓ Self-Learning aktiv (kb_capture_session, kb_capture_fix)
- **Phase 3** ✓ Obsidian-Vault eingerichtet (`~/obsidian-vaults/claude-kb/`)

Homeserver-Migration wurde bewusst verworfen — stdio-MCP ist schneller,
Claude Code läuft nur auf dem Laptop, und Backup lässt sich einfacher lösen.
