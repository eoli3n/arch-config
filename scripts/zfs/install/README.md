### How to Use

Boot latest archiso

```bash
$ loadkeys fr

# Init ZFS module and install git
$ curl -s https://eoli3n.github.io/archzfs/init | bash

# Get install scripts
$ git clone https://github.com/eoli3n/arch-config
$ cd arch-config/scripts/zfs/install
$ ./01-configure.sh
$ ./02-install.sh
```

### DualBoot Support

After installing Void Linux with [void-config](https://github.com/eoli3n/void-config/tree/master/scripts/install), run ``01-configure.sh`` and select ``dualboot`` in the menu.

### EFI install

- sda1  
  /efi  
  FAT used as esp
- sda2  
  ZFS pool

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

### Debug

```bash
$ ./01-configure.sh debug
$ ./02-install.sh debug
$ pacman -S pastebinit
$ pastebinit -b sprunge.us configure.log
$ pastebinit -b sprunge.us install.log
```

##### Check EFI content
```bash
$ pacman -S dracut
$ lsinitrd /efi/EFI/ZBM/*
```
