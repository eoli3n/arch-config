### Partition table

- sda1
  /efi
  FAT used as esp
- sda2
  ZFS pool

No swap

### Install

Boot latest archiso.

```
loadkeys fr
pacman -Sy git
git clone https://github.com/eoli3n/arch-config
cd arch-config/scripts/install
./00-init.sh
./01-configure.sh
./02-install.sh
```
