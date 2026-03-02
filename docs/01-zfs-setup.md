# 01 — ZFS-Pool erstellen und konfigurieren

Voraussetzung: NixOS ist installiert und du bist per SSH verbunden (Anleitung 00).

Alle Befehle auf dem **Server** (per SSH).

---

## HDDs identifizieren

```bash
ls -la /dev/disk/by-id/ | grep ata | grep -v part

# Beispiel-Ausgabe:
# ata-WDC_WD120EFBX-68B0EN0_WD-XXXXXXX1 → /dev/sda
# ata-WDC_WD120EFBX-68B0EN0_WD-XXXXXXX2 → /dev/sdb
```

Notiere dir beide `by-id`-Pfade.

## ZFS-Pool erstellen (Mirror mit Encryption)

Ersetze die Pfade mit deinen echten `by-id`-Pfaden:

```bash
sudo zpool create \
  -o ashift=12 \
  -o autotrim=on \
  -O acltype=posixacl \
  -O xattr=sa \
  -O compression=lz4 \
  -O normalization=formD \
  -O relatime=on \
  -O encryption=aes-256-gcm \
  -O keyformat=passphrase \
  -O keylocation=prompt \
  -O mountpoint=none \
  tank mirror \
  /dev/disk/by-id/ata-WDC_WD120EFGX-68CPHN0_WD-B018UD3D \
  /dev/disk/by-id/ata-WDC_WD120EFGX-68CPHN0_WD-B01AEHZD
```

Du wirst nach einer **Passphrase** gefragt.

> **⚠ Passwort-Strategie:** Verwende in der Installationsphase ein kurzes
> Passwort wie `tank`. Du musst es **nach jedem Reboot** eingeben (per SSH).
> Ein starkes Passwort kommt in der Härtungsphase (Anleitung 18).

**Was diese Optionen bedeuten:**

- `ashift=12`: 4K-Sektoren (Standard für moderne HDDs)
- `compression=lz4`: Transparente Kompression (~10-30% Platz gespart)
- `encryption=aes-256-gcm`: Alles auf dem Pool ist verschlüsselt
- `mirror`: RAID1 — beide Platten spiegeln sich gegenseitig

## Datasets erstellen

```bash
sudo zfs create -o mountpoint=/tank/backup tank/backup
sudo zfs create -o mountpoint=/tank/media tank/media
sudo zfs create -o mountpoint=/tank/documents tank/documents
sudo zfs create -o mountpoint=/tank/photos tank/photos
```

## Pool-Status prüfen

```bash
sudo zpool status
# Muss zeigen: state: ONLINE, beide Platten im Mirror

sudo zfs list
# NAME             USED  AVAIL  REFER  MOUNTPOINT
# tank             ...   ~10.9T ...    none
# tank/backup      ...   ...    ...    /tank/backup
# tank/documents   ...   ...    ...    /tank/documents
# tank/media       ...   ...    ...    /tank/media
# tank/photos      ...   ...    ...    /tank/photos
```

## Berechtigungen setzen

```bash
sudo chown -R philip:philip /tank/backup
sudo chown -R philip:philip /tank/media
sudo chown -R philip:philip /tank/documents
sudo chown -R philip:philip /tank/photos

# Media-Unterordner erstellen
mkdir -p /tank/media/{filme,serien,musik,audiobooks,podcasts}
```

## NixOS-Konfiguration reaktivieren

Jetzt wo der Pool existiert, die deaktivierten ZFS-Einträge wieder aktivieren:

```bash
cd ~/nixos-config
nano modules/server/hardware/zfs.nix
```

Entferne die `#` vor:
- `boot.zfs.extraPools = [ "tank" ];`
- Dem gesamten `services.sanoid = { ... };` Block

Ebenso in `modules/server/storage/default.nix`:
- `./nightly-sync.nix` einkommentieren

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#homeserver
```

## Pool-Unlock nach jedem Reboot

Da der Pool verschlüsselt ist, muss er nach jedem Boot entsperrt werden:

```bash
sudo zfs load-key tank
# Passphrase eingeben (Installationsphase: "tank")
sudo zfs mount -a
```

> **Tipp:** Du kannst dir einen Alias dafür anlegen. In `home/server/shell.nix`
> ist bereits `zl` für `zfs list` definiert.

## Erster Scrub

```bash
sudo zpool scrub tank
# Bei 2×12 TB dauert der erste Scrub mehrere Stunden.
# Fortschritt: sudo zpool status tank
```

## Nützliche ZFS-Befehle

```bash
sudo zpool status -v tank                        # Pool-Status
sudo zfs list -o name,used,avail,compressratio   # Speicher + Kompression
sudo zfs list -t snapshot                         # Snapshots
sudo zfs snapshot -r tank@manual-$(date +%Y%m%d)  # Manueller Snapshot
sudo smartctl -a /dev/disk/by-id/ata-WDC_...      # SMART-Status einer HDD
```

---

## Nächste Schritte

→ **Anleitung 02:** Secrets mit sops-nix einrichten
