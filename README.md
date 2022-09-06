# Arch linux configuration

This repository contains, free as in freedom, scripts to configure your archiso environment.

The current change log can be found [here](CHANGELOG.md).

See my [archzfs](https://archzfs.leibelt.de) page if you want to know more.

This is a hard fork from [eoli3n/archiso-zfs](https://github.com/eoli3n/arch-config). For the history, [eoli3n](https://github.com/eoli3n/arch-config/pull/4) asked me kindly to do a hard fork, so I did.

## How to use

Boot your archiso, either an iso with [build in OpenZFS support](https://archzfs.leibelt.de/#archiso-with-openzfs-support) or by [adding OpenZFS support on runtime](https://archzfs.leibelt.de/#archiso-openzfs-setup).

```
git clone --recursive https://github.com/stevleibelt/arch-linux-configuration
#if you want to setup upstream too
#git remote add upstream https://github.com/eoli3n/arch-config
#git fetch upstream

#bo: zfs installer section
cd scripts/zfs/install
bash 01-configure.sh
bash 02-configure.sh
#eo: zfs installer section

#bo: zfs recover section
bash 01-mount.sh
#do what you need to do
bash 02-umount.sh
#eo: zfs recover section
```

## Features

### ZFS root features

* Native encryption aes-256-gcm
* Zstd compression on all datasets
* Boot Environments managed with [zfsbootmenu](https://zfsbootmenu.org/)
  * /boot included in ZFS
* No swap
* [Netboot recovery](https://eoli3n.github.io/archlinux/2020/04/25/recovery.html)

### BTRFS root features

* LUKS encryption aes-xts-plain64
* Zstd compression on all subvolumes
* Bootable BTRFS snapshot managed with [snapper](https://github.com/openSUSE/snapper) and [grub-btrfs](https://github.com/Antynea/grub-btrfs)
* Encrypted swap
* Separated VFAT /boot
* [Netboot recovery](https://eoli3n.github.io/archlinux/2020/04/25/recovery.html)

## Links

* [eoli3n/archiso-zfs](https://github.com/eoli3n/archiso-zfs) - 20220820

