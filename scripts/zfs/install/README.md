### EFI install

- sda1
  /boot
  FAT used as esp
- sda2
  ZFS pool


##### Boot latest arch iso

``01-configure.sh`` will 
- Create partition scheme
- Format everything
- Mount partitions

``02-install.sh`` will
- Configure mirrors
- Install Arch Linux and kernel
- Generate initramfs
- Configure hostname, locales, keymap, network
- Install and configure bootloader
- Generate users and passwords

Boot latest archiso

```
loadkeys fr
pacman -Sy git
git clone https://github.com/eoli3n/arch-config
cd arch-config/scripts/install
./01-configure.sh
./02-install.sh
```
