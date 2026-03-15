# NixOS-Installation auf dem ASRock N100DC-ITX

Diese Anleitung führt dich von der blanken Hardware bis zum laufenden NixOS-System.
Sie basiert auf einer realen Installation und deckt alle typischen Stolperfallen ab.

---

## Passwort-Strategie (gilt für die gesamte Installation)

Während der Installationsphase verwenden wir **bewusst einfache Passwörter**, um Lockout-Situationen zu vermeiden. Erst wenn alles läuft, werden in der **Härtungsphase** (Anleitung 18) sichere Passwörter gesetzt.

| Passwort | Phase | Wert | Manuell eingeben? |
|----------|-------|------|-------------------|
| User-Login (philip) | Installation | `server` | Nur bei Konsolen-Login am Server |
| SSH-Key Passphrase | Installation | *(leer)* | Nein — einfach Enter drücken |
| ZFS-Pool Passphrase | doc 01 | `tank` | **Ja — nach JEDEM Reboot per SSH!** |
| SOPS-Secrets | doc 02 | Generierte Tokens | Nein — liegen im System |

> **⚠ ZFS-Passphrase beachten:** Die ZFS-Verschlüsselung fragt bei jedem Boot nach der Passphrase. In der Installationsphase nutzen wir ein kurzes Passwort (`tank`), weil du es oft eingeben wirst. In der Härtungsphase (doc 18) wird es durch ein starkes Passwort ersetzt.

---

## Voraussetzungen

- ASRock N100DC-ITX mit montierter NVMe-SSD und 32 GB DDR4
- 2× WD Red Plus 12 TB (eingebaut, werden erst in Anleitung 01 konfiguriert)
- Leicke 19V/90W Netzteil angeschlossen
- Ethernet-Kabel zum Switch/pfSense
- USB-Stick (mindestens 2 GB)
- Einen zweiten Rechner ("Laptop") mit SSH-Client und Terminal
- Temporär: Monitor + Tastatur am N100 (nur für den Boot)

---

## Phase 1: NixOS-ISO vorbereiten

### 1.1 ISO herunterladen

Auf deinem **Laptop**:

```bash
wget https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-x86_64-linux.iso
```

### 1.2 USB-Stick flashen

**Wichtig:** Ordnernamen im Pfad dürfen keine Leerzeichen enthalten!

```bash
# Zuerst: USB-Stick identifizieren
lsblk
# Zeigt z.B.:
# sda      8:0    0  500G  0 disk     ← Deine Festplatte (NICHT die!)
# sdb      8:0    1  16G   0 disk     ← Dein USB-Stick (die!)

# Linux/macOS — ersetze /dev/sdb mit DEINEM USB-Stick:
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sda bs=4M status=progress
sync
```

> **Achtung:** `/dev/sda` ist nur ein Beispiel! Prüfe mit `lsblk` welches
> Gerät dein USB-Stick ist. Die falsche Wahl überschreibt deine Festplatte!

**Windows:** Nutze Rufus (https://rufus.ie) im DD-Modus.

### 1.3 BIOS-Einstellungen (ASRock N100DC-ITX)

Starte den Server mit angeschlossenem Monitor, drücke **F2** beim Boot:

1. **Boot → Boot Option #1** → USB-Stick auswählen
2. **Advanced → CPU Configuration → Intel SpeedStep** → Enabled
3. **Advanced → CPU Configuration → C-States** → Enabled
4. **Advanced → CPU Configuration → Package C State Support** → Enabled
5. **Advanced → ACPI → PCIE ASPM Support** → Auto
6. **Advanced → ACPI → PCIe Devices Power On** → Enabled
7. **Advanced → SATA Configuration → Aggressive Link Power Management** → Disabled
8. **Boot → Boot Configuration → Restore on AC Power Loss** → Power On
9. **Security → Secure Boot** → Disabled
10. Speichern + Neustart (**F10**)

> **Warum diese Einstellungen?**
> - Package C-States: Spart 3-5W im Idle (CPU-Chip schläft komplett)
> - SATA ALPM Disabled: ZFS reagiert empfindlich auf SATA-Link-Resets
> - PCIe Devices Power On: Ermöglicht Wake-on-LAN als Rückversicherung
> - Restore on AC Power Loss: Server startet automatisch nach Stromausfall

---

## Phase 2: Booten und Netzwerk

### 2.1 Vom USB-Stick booten

Wähle im Boot-Menü den USB-Stick. NixOS startet in eine Root-Shell.

> **Wichtig:** Stelle sicher, dass der USB-Stick richtig im Port sitzt!
> Ein lockerer USB-Stick verursacht I/O-Errors bei allen Befehlen.

### 2.2 Tastaturlayout setzen

```bash
sudo -i
loadkeys de
```

### 2.3 Netzwerkverbindung prüfen

```bash
ip addr show
ping -c 3 1.1.1.1
```

Falls kein Netzwerk:

```bash
ip link                    # Zeigt z.B. enp1s0
ip link set enp1s0 up
dhcpcd enp1s0
```

### 2.4 SSH aktivieren (ab jetzt vom Laptop arbeiten)

Auf der Minimal-ISO bist du bereits root. Setze ein temporäres Passwort:

```bash
passwd
# Gib ein einfaches Passwort ein (z.B. "install") — nur für diese Session
```

SSH ist auf der Minimal-ISO bereits aktiv. Finde deine IP-Adresse:

```bash
ip addr show | grep "inet "
# Beispiel-Ausgabe:
#   inet 127.0.0.1/8 scope host lo                  ← Ignorieren (localhost)
#   inet 192.168.1.185/24 brd ... scope global enp1s0  ← DAS ist deine Server-IP
```

Die IP auf dem physischen Interface (z.B. `enp1s0`) ist die richtige — **nicht** die `127.0.0.1`.
Notiere diese IP (im Beispiel: `192.168.1.185`).

### 2.5 Vom Laptop per SSH verbinden

Auf dem **Laptop** (nicht am Server!):

```bash
ssh root@192.168.1.185
```

> Beim **ersten** Verbinden kommt: `The authenticity of host ... can't be established.`
> Das ist normal. Tippe `yes` ein und drücke Enter.

Gib das Passwort ein, das du eben gesetzt hast.

---

## Phase 3: Disk-Layout und Konfiguration vorbereiten

### 3.1 NVMe-SSD identifizieren

```bash
lsblk
# Ausgabe z.B.:
# nvme0n1     259:0    0 931.5G  0 disk
# ├─nvme0n1p1 259:1    0     1G  0 part    ← Evtl. alte Partitionen
# └─nvme0n1p2 259:2    0 930.5G  0 part
# sda           8:0    0  10.9T  0 disk     ← HDD 1 (nicht anfassen)
# sdb           8:16   0  10.9T  0 disk     ← HDD 2 (nicht anfassen)

# Ausgabe tatsächlich
#NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS  
#loop0         7:0    0   1.4G  1 loop /nix/.ro-store  
#sda           8:0    0  10.9T  0 disk    
#├─sda1        8:1    0  10.9T  0 part    
#└─sda9        8:9    0     8M  0 part    
#sdb           8:16   0  10.9T  0 disk    
#├─sdb1        8:17   0  10.9T  0 part    
#└─sdb9        8:25   0     8M  0 part    
#sdc           8:32   1 114.6G  0 disk    
#├─sdc1        8:33   1   1.5G  0 part /iso  
#└─sdc2        8:34   1     3M  0 part    
#nvme0n1     259:0    0 931.5G  0 disk    
#├─nvme0n1p1 259:1    0   512M  0 part    
#└─nvme0n1p2 259:2    0   931G  0 part

# Stabilen Geräte-Pfad ermitteln:
ls -la /dev/disk/by-id/ | grep nvme
# Nimm den Pfad OHNE -part und OHNE _1 am Ende, z.B.:
#   nvme-Samsung_SSD_980_1TB_S649NU0W402228A → ../../nvme0n1      ← DEN HIER

Ausgabe: 
lrwxrwxrwx  1 root root  13 Mar  2 15:17 nvme-eui.002538d431a08cb5 -> ../../nvme0n1  
lrwxrwxrwx  1 root root  15 Mar  2 15:17 nvme-eui.002538d431a08cb5-part1 -> ../../nvme0n1p1  
lrwxrwxrwx  1 root root  15 Mar  2 15:17 nvme-eui.002538d431a08cb5-part2 -> ../../nvme0n1p2  
lrwxrwxrwx  1 root root  13 Mar  2 15:17 nvme-Samsung_SSD_980_1TB_S649NU0W402228A -> ../../nvme0n1  # <-- DEN
lrwxrwxrwx  1 root root  13 Mar  2 15:17 nvme-Samsung_SSD_980_1TB_S649NU0W402228A_1 -> ../../nvme0n1  
lrwxrwxrwx  1 root root  15 Mar  2 15:17 nvme-Samsung_SSD_980_1TB_S649NU0W402228A_1-part1 -> ../../nvme0n1p1  
lrwxrwxrwx  1 root root  15 Mar  2 15:17 nvme-Samsung_SSD_980_1TB_S649NU0W402228A_1-part2 -> ../../nvme0n1p2  
lrwxrwxrwx  1 root root  15 Mar  2 15:17 nvme-Samsung_SSD_980_1TB_S649NU0W402228A-part1 -> ../../nvme0n1p1  
lrwxrwxrwx  1 root root  15 Mar  2 15:17 nvme-Samsung_SSD_980_1TB_S649NU0W402228A-part2 -> ../../nvme0n1p2
```

Notiere den Pfad, z.B.: `/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S649NU0W402228A`

### 3.2 SSH-Key auf dem Laptop vorbereiten

Falls du noch keinen SSH-Key hast, erstelle einen auf dem **Laptop**:

```bash
ssh-keygen -t ed25519 -C "philip@laptop"
# Bei "Enter passphrase": LEER LASSEN (einfach Enter drücken)
# → In der Härtungsphase (doc 18) kannst du eine Passphrase nachträglich setzen
```

> **Warum keine Passphrase jetzt?** Während der Installation wirst du sehr oft
> SSH-Verbindungen aufbauen. Eine Passphrase nervt und ein Vergessen sperrt dich aus.
> Nachträglich setzen geht jederzeit: `ssh-keygen -p -f ~/.ssh/id_ed25519`

Den Public Key anzeigen und **kopieren** (brauchst du gleich):

```bash
cat ~/.ssh/id_ed25519.pub
# Ausgabe z.B.: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... philip@laptop
```

### 3.3 Repo auf dem Laptop klonen/vorbereiten

Das neue Repo enthält Configs für **beide** Maschinen (Server + Laptop).
Auf dem **Laptop**:

```bash
cd ~
git clone git@github.com:Mudslider/nixos-config.git
cd nixos-config
```

Falls das Repo noch nicht auf GitHub existiert:

```bash
mkdir -p ~/nixos-config && cd ~/nixos-config
git init
# → Dateien aus diesem Paket reinkopieren, dann:
git add -A
git commit -m "Initial unified NixOS config"
```

### 3.4 Konfiguration anpassen

Alle Änderungen auf dem **Laptop** im Repo `~/nixos-config`:

#### NVMe-Pfad eintragen

```bash
nano hosts/homeserver/disko-config.nix
# Ersetze: /dev/disk/by-id/nvme-DEIN_NVME_MODELL
# Mit deinem notierten Pfad
```

#### SSH-Key eintragen (KRITISCH!)

```bash
nano hosts/homeserver/default.nix
```

Ersetze **beide** Stellen mit `"ssh-ed25519 AAAA... philip@laptop"` durch
deinen echten Public Key aus `cat ~/.ssh/id_ed25519.pub`.

> **⚠ WICHTIG:** Benutze Copy-Paste! Den Key von Hand abtippen führt zu
> Fehlern und du sperrst dich aus.
>
> **⚠ LESSON LEARNED:** Wenn der SSH-Key nicht stimmt, brauchst du den
> Konsolen-Zugang oder musst vom USB-Stick booten. Deshalb ist in der
> Installationsphase Passwort-Auth aktiviert — als Rettungsanker.

#### hostId generieren und eintragen

```bash
head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
# Ausgabe z.B.: a1b2c3d4

nano hosts/homeserver/default.nix
# Ersetze: networking.hostId = "XXXXXXXX";
# Mit:     networking.hostId = "a1b2c3d4";
```

#### Interface-Name prüfen

Auf dem **Server** (SSH-Sitzung):

```bash
ip link
# Zeigt z.B.: enp1s0 oder enp2s0 oder eno1
```

Falls der Name **nicht** `enp1s0` ist:

```bash
# Auf dem Laptop:
nano modules/server/networking/static-ip.nix
# Ersetze enp1s0 mit deinem tatsächlichen Interface-Namen
```

### 3.5 Konfiguration auf den Server kopieren

Auf dem **Laptop**:

```bash
scp -r ~/nixos-config root@192.168.1.185:/tmp/
```

> **"REMOTE HOST IDENTIFICATION HAS CHANGED"** — Normal nach jedem USB-Stick-Boot:
> ```bash
> ssh-keygen -R 192.168.1.185
> # Falls "not a valid known_hosts file": rm ~/.ssh/known_hosts
> ```
> Dann `scp` nochmal versuchen.

---

## Phase 4: Partitionierung und Installation

### 4.1 Disko ausführen (automatische Partitionierung)

Auf dem **Server**:

```bash
cd /tmp/nixos-config

nix --experimental-features "nix-command flakes" run github:nix-community/disko -- \
  --mode disko hosts/homeserver/disko-config.nix
```

### 4.2 Partitionierung prüfen

```bash
lsblk
# nvme0n1
# ├─nvme0n1p1   512M  /mnt/boot
# └─nvme0n1p2   Rest  /mnt

mount | grep mnt
# /dev/nvme0n1p2 on /mnt type ext4 ...   ← Root ✓
# /dev/nvme0n1p1 on /mnt/boot type vfat  ← Boot ✓
```

### 4.3 Hardware-Konfiguration generieren

```bash
nixos-generate-config --no-filesystems --root /mnt
```

### 4.4 Config ins Zielsystem kopieren

```bash
# Config kopieren
cp -r /tmp/nixos-config /mnt/home/

# Hardware-Config übernehmen
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/home/nixos-config/hosts/homeserver/hardware-configuration.nix
```

### 4.5 Nix aktualisieren (Bug-Workaround)

Die NixOS Minimal-ISO hat manchmal einen Nix-Bug (`Assertion failed`). Vorbeugend:

```bash
nix-env -iA nixos.nix
```

### 4.6 NixOS installieren

```bash
nixos-install --flake /mnt/home/nixos-config#homeserver --no-root-passwd
```

Das dauert 10-20 Minuten (Downloads + Build).

> Warnings wie `programs.git.userName has been renamed` sind harmlos.

Am Ende sollte stehen: **`installation finished!`**

### 4.7 Neustart

```bash
reboot
```

**Zieh den USB-Stick heraus**, bevor das System neu startet!

---

## Phase 5: Erster Boot und Validierung

### 5.1 SSH-Verbindung testen

Auf dem **Laptop**:

```bash
# Alten Host-Key entfernen (der war vom USB-Stick):
ssh-keygen -R 192.168.178.10

ssh philip@192.168.178.10
```

> Beim ersten Verbinden: `yes` bestätigen.

> **Falls "Permission denied":** Passwort-Auth ist als Rettungsanker aktiviert.
> Versuche `ssh philip@192.168.178.10` und gib `server` als Passwort ein.
> Dann den SSH-Key in der Config korrigieren und neu rebuilden.

### 5.2 System prüfen

```bash
nixos-version
ip addr show
ping -c 3 1.1.1.1
lsblk                         # NVMe + 2× HDD sichtbar?
nproc                          # Sollte 4 zeigen (4 E-Cores)
```

### 5.3 Config-Verzeichnis aufräumen

```bash
sudo chown -R philip:philip /home/philip/nixos-config
cd ~/nixos-config
```

### 5.4 Git-Repository einrichten

```bash
cd ~/nixos-config
git init
git add -A
git commit -m "Initial NixOS homeserver config"
```

Falls du das Repo auf GitHub haben willst:

```bash
# SSH-Key vom Server auf GitHub hinterlegen:
ssh-keygen -t ed25519 -C "philip@homeserver"
cat ~/.ssh/id_ed25519.pub
# → Auf GitHub: Settings → SSH and GPG keys → New SSH key

# Remote hinzufügen:
git remote add origin git@github.com:Mudslider/nixos-config.git
git push -u origin main
```

> **Tipp:** Auf dem Laptop das gleiche Repo klonen, sodass du von beiden
> Maschinen aus Änderungen pushen/pullen kannst. Kein manuelles Kopieren mehr!

---

## Fehlerbehebung

### "Assertion failed" / "Aborted (core dumped)" bei nixos-install

Nix-Bug auf der Live-ISO. Lösung:

```bash
nix-env -iA nixos.nix
# Dann nixos-install nochmal ausführen
```

### "efiSysMountPoint '/boot' is not a mounted partition"

```bash
mount /dev/nvme0n1p1 /mnt/boot
# Dann nixos-install nochmal
```

### "Invalid value given to networking.hostId"

```bash
head -c4 /dev/urandom | od -A none -t x4 | tr -d ' '
nano /mnt/home/nixos-config/hosts/homeserver/default.nix
```

### "attribute 'nextcloud30' missing"

`nextcloud.nix` ist noch aktiv aber die Paketversion hat sich geändert. Prüfe dass `./nextcloud.nix` in `modules/server/services/default.nix` auskommentiert ist.

### SSH: "Permission denied (publickey)"

**Option A:** Passwort als Fallback (Installationsphase):

```bash
ssh philip@192.168.178.10
# Passwort: server
```

**Option B:** Vom USB-Stick booten und Key korrigieren:

```bash
passwd                          # Temporäres Passwort setzen
# Vom Laptop: SSH-Key kopieren
scp ~/.ssh/id_ed25519.pub root@192.168.1.185:/tmp/key.pub

# Am Server:
mount /dev/nvme0n1p2 /mnt
mount /dev/nvme0n1p1 /mnt/boot
cat /tmp/key.pub
nano /mnt/home/nixos-config/hosts/homeserver/default.nix
# Beide ssh-ed25519-Zeilen ersetzen (Copy-Paste, NICHT sed!)

nix-env -iA nixos.nix
nixos-install --flake /mnt/home/nixos-config#homeserver --no-root-passwd
reboot
# USB-Stick raus!
```

> **Warum nicht `sed`?** SSH-Keys enthalten Sonderzeichen (`+`, `/`, `=`),
> die `sed` als Steuerzeichen interpretiert. Immer `nano` mit Copy-Paste!

### SSH: "REMOTE HOST IDENTIFICATION HAS CHANGED"

Normal nach jedem USB-Stick-Boot:

```bash
ssh-keygen -R 192.168.1.185
# Falls "not a valid known_hosts file": rm ~/.ssh/known_hosts
```

### "chown: invalid group: 'philip:philip'"

Prüfe ob `users.groups.philip = {};` in `hosts/homeserver/default.nix` vorhanden ist.

### Boot schlägt fehl (kein Bootmedium)

Vom USB-Stick booten und wiederholen:

```bash
mount /dev/nvme0n1p2 /mnt
mount /dev/nvme0n1p1 /mnt/boot
nix-env -iA nixos.nix
nixos-install --flake /mnt/home/nixos-config#homeserver --no-root-passwd
reboot
```

---

## Nächste Schritte

→ **Anleitung 01:** ZFS-Pool erstellen und konfigurieren
→ **Anleitung 02:** Secrets mit sops-nix einrichten
→ **Anleitung 03:** Netzwerk und Caddy aufsetzen
→ Dann die einzelnen Dienste aktivieren (Anleitungen 04-15)
→ **Anleitung 18:** Systemhärtung (am Ende, wenn alles läuft)
