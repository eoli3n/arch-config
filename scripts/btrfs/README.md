### Partition table

- sda1
  /boot
  FAT used as esp
- sda2
  swap
  reencrypted at each boot
- sda3
  /
  BTRFS over LUKS

### Install

Boot latest archiso.

```
loadkeys fr
pacman -Sy git
git clone https://github.com/eoli3n/arch-config
cd arch-config/scripts/install
./01-configure.sh
./02-install.sh
```
