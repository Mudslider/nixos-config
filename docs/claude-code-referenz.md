# Claude Code — Referenz für dieses Projekt

Nützliche Slash-Commands, Skills und Tastenkürzel bei der Arbeit mit NixOS, Homeserver und VPS.

---

## Slash-Commands (eingebaut)

### Session & Kontext

| Command | Beschreibung | Usecase |
|---------|-------------|---------|
| `/context` | Zeigt Context-Auslastung als Diagramm | Prüfen ob der Kontext voll läuft — bei langen Sessions wie Homeserver-Debugging |
| `/compact` | Komprimiert die Conversation-History | Wenn `/context` >70% zeigt und wir noch viel vorhaben |
| `/compact <Fokus>` | Komprimiert mit Schwerpunkt | z.B. `/compact focus on ZFS and Immich issues` um relevantes zu behalten |
| `/clear` | Setzt die Conversation komplett zurück | Neues Thema starten (z.B. von Immich zu VPS-Setup wechseln) |
| `/resume` | Frühere Conversation fortsetzen | Gestrige Session wiederherstellen wenn man weitermachen will |
| `/rename <Name>` | Session umbenennen | z.B. `/rename immich-db-reset` um Sessions wiederzufinden |
| `/fork` | Conversation an diesem Punkt verzweigen | Alternative Lösungswege ausprobieren ohne Hauptsession zu verlieren |
| `/rewind` | Conversation/Code auf vorherigen Stand zurücksetzen | Wenn eine Änderung schiefgelaufen ist — Code-Änderungen rückgängig machen |
| `/export` | Conversation als Textdatei speichern | Debugging-Session dokumentieren bevor sie komprimiert wird |

### Modell & Performance

| Command | Beschreibung | Usecase |
|---------|-------------|---------|
| `/model` | Modell wechseln | Interaktiv zwischen Sonnet und Opus wählen |
| `/model opus` | Direkt zu Opus wechseln | Bei komplexen Architektur-Entscheidungen (z.B. Backup-Tiering-Design) |
| `/model sonnet` | Direkt zu Sonnet wechseln | Für Routineaufgaben (Befehle, einfache Edits) |
| `/fast` | Fast Mode umschalten | Schnellere Antworten bei einfachen Tasks |
| `/effort high` | Aufwand erhöhen | Bei kniffligen Bugs (z.B. ZFS-Mount-Problem) |
| `/cost` | Token-Kosten der Session anzeigen | Nach langen Debugging-Sessions |

### Navigation & Dateien

| Command | Beschreibung | Usecase |
|---------|-------------|---------|
| `/diff` | Interaktiver Diff-Viewer für Änderungen | Vor `git add` alle geänderten Dateien überprüfen |
| `/add-dir <Pfad>` | Weiteres Verzeichnis zur Session hinzufügen | z.B. `/add-dir ~/.ssh` wenn SSH-Keys bearbeitet werden |
| `/security-review` | Sicherheitsanalyse der ausstehenden Änderungen | Vor dem Pushen von Firewall- oder SOPS-Änderungen |

### System & Diagnose

| Command | Beschreibung | Usecase |
|---------|-------------|---------|
| `/status` | Version, Modell, Account, Verbindung anzeigen | Wenn Claude sich komisch verhält |
| `/doctor` | Installation und Einstellungen diagnostizieren | Bei Verbindungsproblemen oder merkwürdigem Verhalten |
| `/permissions` | Erlaubte Tools anzeigen/ändern | Prüfen welche Bash-Befehle ohne Nachfrage ausgeführt werden |
| `/hooks` | Konfigurierte Hooks anzeigen | Automatisierungen verstehen die im Hintergrund laufen |
| `/memory` | CLAUDE.md und Auto-Memory bearbeiten | Projektkontext aktualisieren nach größeren Umbauarbeiten |

### Hilfe & Info

| Command | Beschreibung | Usecase |
|---------|-------------|---------|
| `/help` | Alle verfügbaren Commands anzeigen | Wenn man nicht mehr weiß was es gibt |
| `/skills` | Verfügbare Skills auflisten | Übersicht über `/simplify`, `/batch` etc. |
| `/release-notes` | Changelog der aktuellen Version | Nach einem Update schauen was neu ist |
| `/feedback` | Bug-Report an Anthropic senden | Wenn Claude sich wirklich falsch verhält |

### Darstellung & Eingabe

| Command | Beschreibung | Usecase |
|---------|-------------|---------|
| `/theme` | Farbschema ändern (hell/dunkel/ANSI) | Terminal-Darstellung anpassen |
| `/vim` | Vim-Modus umschalten | Für Vim-Nutzer: Eingabe im Vim-Stil |
| `/terminal-setup` | Terminal-Tastenkürzel konfigurieren | Shift+Enter für Zeilenumbruch einrichten |

---

## Skills

Skills sind mächtigere Commands die eigenständig Agenten starten.

| Skill | Beschreibung | Usecase |
|-------|-------------|---------|
| `/simplify` | Überprüft geänderte Dateien auf Qualität, Redundanzen und Effizienz | Nach größeren Umbauten an `modules/server/` ausführen |
| `/batch <Aufgabe>` | Führt große Änderungen parallelisiert durch (5-30 unabhängige Einheiten) | z.B. alle Dienste auf eine neue Option umstellen |
| `/loop <Interval> <Task>` | Führt einen Task regelmäßig aus | `/loop 5m check if nrs on homeserver finished` |
| `/debug` | Analysiert die aktuelle Claude-Session auf Probleme | Wenn Claude in einer Schleife steckt oder sich merkwürdig verhält |
| `/security-review` | Sicherheitsanalyse ausstehender Code-Änderungen | Vor dem Pushen von Firewall- oder SOPS-Änderungen |
| `/pr-comments` | Lädt GitHub PR-Kommentare | Wenn man Feedback zu einem offenen PR einarbeiten will |

---

## CLI-Flags (beim Start)

```bash
# Modell direkt beim Start wählen
claude --model opus

# Letzte Session fortsetzen
claude -c

# Bestimmte Session nach Name fortsetzen
claude -r "immich-setup"

# In einem bestimmten Verzeichnis starten
claude --add-dir ~/nixos-config

# Maximales Budget für nicht-interaktive Nutzung setzen
claude -p "Erkläre diesen Fehler" --max-budget-usd 1.00
```

---

## Tastenkürzel

| Kürzel | Beschreibung | Usecase |
|--------|-------------|---------|
| `Ctrl+C` | Aktuelle Ausgabe abbrechen | Wenn Claude zu lang braucht oder in die falsche Richtung geht |
| `Ctrl+L` | Terminal-Ausgabe leeren | Übersicht behalten nach langen Outputs |
| `Ctrl+O` | Verbose-Output umschalten | Zeigt welche Tools Claude verwendet — nützlich zum Nachvollziehen |
| `Ctrl+R` | Befehlshistorie durchsuchen | Letzten langen Befehl wiederfinden |
| `Shift+Tab` | Permission-Modus wechseln | Zwischen Plan-Modus und Auto-Approve wechseln |
| `Esc Esc` | Letzte Änderung rückgängig | Schnelle Alternative zu `/rewind` |
| `!` am Anfang | Bash-Modus | `!git status` direkt ausführen ohne Claude zu fragen |
| `@` am Anfang | Datei-Autocomplete | `@modules/server/networking/caddy.nix` schnell referenzieren |

---

## Nützliche Kombinationen für dieses Projekt

```bash
# Vor größeren Änderungen: Plan-Modus aktivieren
# → Shift+Tab drücken, dann Aufgabe beschreiben

# Lange Homeserver-Debugging-Session sichern:
/rename homeserver-zfs-debug
/export

# Vor einem nrs auf dem Server:
/security-review

# Nach vielen Dateiänderungen:
/simplify

# Context-Überwachung bei langen Sessions:
/context
# → Wenn >70%: /compact
```

---

## Schnell-Referenz: Unser Workflow

```
Änderung planen      → Shift+Tab (Plan-Modus)
Dateien bearbeiten   → Claude direkt fragen
Änderungen prüfen    → /diff
Sicherheit prüfen    → /security-review
Committen & pushen   → git add / commit / push (Laptop)
Server rebuilden     → nrs (Homeserver per SSH)
Context voll?        → /compact
Session sichern?     → /export oder /rename
```
