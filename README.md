### ZFS root features

- Native encryption aes-256-gcm
- lz4 compression on all datasets
- Boot Environments managed with [zectl](https://github.com/johnramsden/zectl)
- No swap
- Separated VFAT /boot
- [Netboot recovery](https://eoli3n.github.io/archlinux/2020/04/25/recovery.html)

### BTRFS root features

- LUKS encryption aes-xts-plain64
- Zstd compression on all subvolumes
- Bootable BTRFS snapshot managed with [snapper](https://github.com/openSUSE/snapper) and [grub-btrfs](https://github.com/Antynea/grub-btrfs)
- Encrypted swap
- Separated VFAT /boot

### Install

- Clone me and my submodules
```
git clone --recursive https://github.com/eoli3n/arch-config
```
- Run OS installer at [scripts/{zfs,btrfs}/install/](scripts/)
- Install packages and configurations with [ansible](ansible)
- Use [dotfiles](https://github.com/eoli3n/dotfiles)
