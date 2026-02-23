# ── Zusätzliche Pakete / Additional packages ─────────────────────
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # ── Kommunikation / Communication ────────────────────────────
    thunderbird

    # ── Büro / Office ────────────────────────────────────────────
    libreoffice-qt                 # Qt integration for Plasma
    obsidian                       # Notizen (Markdown)

    # ── Fotografie & Grafik / Photography & Graphics ─────────────
    darktable
    gimp

    # ── Medien / Media ───────────────────────────────────────────
    vlc
    audacity

    # ── Secrets ──────────────────────────────────────────────────
    sops
    age                            # age encryption backend for sops
    bitwarden-desktop              # Bitwarden-Client   # ── Werkzeuge / Utilities ────────────────────────────────────
    git
    wget
    curl
    unzip
    htop
    pciutils                       # lspci (verify GPU bus IDs)
    usbutils                       # lsusb
  ];
}
