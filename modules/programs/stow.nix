# ── GNU Stow – Dotfile-Management ────────────────────────────────
#
# Stow verwaltet Symlinks von ~/dotfiles nach ~/ und ~/.config/.
# Damit bleiben Benutzereinstellungen (KDE, Neovim, Git, etc.)
# versionskontrolliert und portabel über mehrere Systeme.
#
# Workflow:
#   cd ~/dotfiles && stow <paket>     # ein Paket verlinken
#   cd ~/dotfiles && stow */          # alle Pakete verlinken
#   cd ~/dotfiles && stow -R */       # alle neu verlinken (restow)
#   cd ~/dotfiles && stow -D <paket>  # Symlinks entfernen
#
# Siehe README.md für eine ausführliche Anleitung.
# ─────────────────────────────────────────────────────────────────
{ pkgs, config, ... }:

let
  # ── .stow-local-ignore ─────────────────────────────────────────
  # WICHTIG: Eine eigene Ignore-Datei überschreibt die
  # eingebaute Standardliste von Stow komplett.
  # Deshalb müssen die sinnvollen Standardeinträge
  # (VCS-Metadaten, Backup-Dateien etc.) hier wiederholt werden.
  stowLocalIgnore = ''
    # ── VCS-Verzeichnisse & Metadaten ────────────────────────────
    RCS
    .+,v
    CVS
    \.\#.+
    \.cvsignore
    \.svn
    _darcs
    \.hg
    \.git
    \.gitignore
    \.gitmodules

    # ── Editor-Artefakte ─────────────────────────────────────────
    .+~
    \#.*\#

    # ── Stow selbst ─────────────────────────────────────────────
    \.stow-local-ignore
    \.stow-global-ignore
    \.stowrc

    # ── Dokumentation & Lizenz ───────────────────────────────────
    ^/README.*
    ^/LICENSE.*
    ^/COPYING
    ^/CHANGELOG.*

    # ── Nix / NixOS ─────────────────────────────────────────────
    ^/flake\.nix
    ^/flake\.lock
    ^/shell\.nix
    ^/default\.nix
    ^/result

    # ── Sonstiges ────────────────────────────────────────────────
    \.DS_Store
    Thumbs\.db
    ^/Makefile
    ^/\.editorconfig
    ^/\.sops\.yaml
  '';

  # ── .stowrc – Standardoptionen ────────────────────────────────
  stowrc = ''
    --target=$HOME
    --restow
    --verbose=1
  '';

  # ── Bootstrap-Skript ───────────────────────────────────────────
  stowBootstrap = pkgs.writeShellScriptBin "dotfiles-setup" ''
    set -euo pipefail

    DOTFILES_DIR="''${DOTFILES_DIR:-$HOME/dotfiles}"

    echo "══════════════════════════════════════════════════════"
    echo "  GNU Stow – Dotfiles Bootstrap"
    echo "══════════════════════════════════════════════════════"
    echo ""

    # ── Dotfiles-Verzeichnis anlegen ─────────────────────────────
    if [ ! -d "$DOTFILES_DIR" ]; then
      echo "📁 Erstelle $DOTFILES_DIR ..."
      mkdir -p "$DOTFILES_DIR"
    fi

    # ── .stow-local-ignore schreiben ─────────────────────────────
    if [ ! -f "$DOTFILES_DIR/.stow-local-ignore" ]; then
      echo "📝 Schreibe .stow-local-ignore ..."
      cat > "$DOTFILES_DIR/.stow-local-ignore" << 'IGNORE'
    ${stowLocalIgnore}
    IGNORE
    fi

    # ── .stowrc schreiben ────────────────────────────────────────
    if [ ! -f "$DOTFILES_DIR/.stowrc" ]; then
      echo "📝 Schreibe .stowrc ..."
      cat > "$DOTFILES_DIR/.stowrc" << 'RC'
    ${stowrc}
    RC
    fi

    # ── Git initialisieren ───────────────────────────────────────
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
      echo "🔧 Initialisiere Git-Repository ..."
      cd "$DOTFILES_DIR"
      ${pkgs.git}/bin/git init
      ${pkgs.git}/bin/git add .
      ${pkgs.git}/bin/git commit -m "Initiales Dotfiles-Setup" --allow-empty
    fi

    echo ""
    echo "✅ Fertig! Dein Dotfiles-Verzeichnis: $DOTFILES_DIR"
    echo ""
    echo "Nächste Schritte:"
    echo "  1. Erstelle Paket-Verzeichnisse, z.B.:"
    echo "       mkdir -p $DOTFILES_DIR/git"
    echo "       mv ~/.gitconfig $DOTFILES_DIR/git/.gitconfig"
    echo ""
    echo "  2. Verlinke einzelne Pakete:"
    echo "       cd $DOTFILES_DIR && stow git"
    echo ""
    echo "  3. Oder verlinke alles auf einmal:"
    echo "       cd $DOTFILES_DIR && stow */"
    echo ""
  '';

in
{
  # ── Pakete ─────────────────────────────────────────────────────
  environment.systemPackages = [
    pkgs.stow
    stowBootstrap              # `dotfiles-setup` Befehl
  ];
}
