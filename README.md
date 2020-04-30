### Features

- BTRFS over LUKS
  - Zstd compression
  - Bootable BTRFS snapshots
- Encrypted swap
- Separated /boot
- [Netboot recovery](https://eoli3n.github.io/archlinux/2020/04/25/recovery.html)

### Install

- Clone me and my submodules
```
git clone --recursive https://github.com/eoli3n/arch-config
```
- Run OS installer at [scripts/install/](scripts/install/)
- Install packages and configurations with [ansible](ansible)
- Use [dotfiles](https://github.com/eoli3n/dotfiles)
