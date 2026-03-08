# NixOS: Passwort-Reset via GRUB Rescue Shell

**Szenario:** Kein Login möglich (z.B. falsches Tastaturlayout nach Reboot, vergessenes Passwort).  
**Getestet auf:** NixOS mit LUKS-Vollverschlüsselung, ThinkPad P15 (playground)

---

## Voraussetzungen

- Physischer Zugang zum Rechner
- LUKS-Passwort bekannt (für die Festplattenverschlüsselung)
- GRUB-Bootloader (systemd-boot: analog, Kernel-Parameter am gleichen Ort)

---

## Schritt-für-Schritt

### 1. Reboot und GRUB öffnen

Rechner neu starten. Im GRUB-Menü **`e`** drücken, um den Bootentry zu bearbeiten.

### 2. Kernel-Parameter anpassen

In der Zeile, die mit `linux` beginnt, ans **Ende der Zeile** folgendes anhängen:

```
init=/bin/sh
```

Mit **`Ctrl+X`** oder **`F10`** booten.

### 3. LUKS-Passwort eingeben

Der Boot stoppt und fragt nach dem LUKS-Passwort — wie gewohnt eingeben. Das verschlüsselte Dateisystem wird automatisch geöffnet und gemountet.

### 4. Root-Shell

Es erscheint eine minimale Root-Shell (`/bin/sh`). 

> ⚠️ **NixOS-Besonderheit:** In dieser Shell ist **kein PATH gesetzt**. Befehle wie `ls`, `mount`, `passwd` sind nicht direkt aufrufbar — auch nicht über `/bin/` oder `/usr/bin/`, da NixOS diese Verzeichnisse nicht klassisch befüllt.

### 5. Passwort ändern

Da kein `passwd`-Befehl im PATH liegt, muss die Binary im Nix-Store gefunden und direkt aufgerufen werden. Das geht mit einem Shell-Glob-Loop (kein `ls` oder `find` nötig):

```sh
for f in /nix/store/*/bin/passwd; do "$f" benutzername; break; done
```

`benutzername` durch den tatsächlichen Unix-Benutzernamen ersetzen (z.B. `polly`).

Das Skript nimmt automatisch den ersten Treffer und führt ihn aus. Anschließend das neue Passwort zweimal eingeben.

### 6. Neu starten

```sh
for f in /nix/store/*/bin/reboot; do "$f" -f; break; done
```

---

## Häufige Fehler

| Fehlermeldung | Ursache | Lösung |
|---|---|---|
| `command not found` (passwd, ls, mount, …) | PATH ist leer in `init=/bin/sh` | Loop-Trick aus Schritt 5 verwenden |
| `No such file or directory` für `/bin/mount` etc. | NixOS hat kein klassisches `/bin` | Gleiches: Nix-Store-Pfad benutzen |
| `/run/current-system/sw/bin/*` nicht vorhanden | `/run` wird erst nach systemd-Init befüllt | Nix-Store direkt ansprechen |

---

## Nach dem Reboot: Ursache beheben

War das Problem ein falsches Tastaturlayout (z.B. nach Migration auf neue Config), folgendes in die Host-Konfiguration eintragen:

```nix
# hosts/thinkpad-p15/default.nix  (oder entsprechende Host-Config)

console.keyMap = "de";
services.xserver.xkb.layout = "de";
services.xserver.xkb.variant = "";
```

Dann rebuild:

```bash
cd ~/nixos-config
sudo nixos-rebuild switch --flake .#hostname
git add hosts/thinkpad-p15/default.nix
git commit -m "fix: add German keyboard layout (console + xkb)"
git push
```

---

*Erstellt: März 2026 — Phil Mudslider / playground (ThinkPad P15)*
