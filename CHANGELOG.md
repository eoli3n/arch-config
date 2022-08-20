# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Open]

### To Add

### zfsbootmenu

* dynamic disk in 01-mount.sh recover script
* see Wayne's World
* periodic trim with timer when host is down ? https://unix.stackexchange.com/a/352596
* reflector systemd timer
* zfs
  * zfs hibernate without swap ?
  * smart test timer ?
  * periodic zfs-scrub
  * pacman hook to "generate-zbm" at each zfs-dkms upgrade
* DNS
  * fix DNS per interface ? as https://github.com/jonathanio/update-systemd-resolved#preventing-leakage-to-corporate-networks
* SERVICES
  * hardware acceleration packages
  * disable ipv6
* IMPROVMENTS
  * move max aur package to community equivalents
* TESTS
  * zfs trim + zfs autoscrub systemd timer
  * reflector at startup
  * test resume in GRUB_CMDLINE_LINUX

### To Change

* solve locale grub : https://forums.archlinux.fr/viewtopic.php?t=13830

## [Unreleased]

### Added

### Changed

## [1.0.0](https://github.com/stevleibelt/arch-linux-configuration/tree/1.0.0) - released at 20220820

### Added

* Added [LICENCE](LICENCE)
* [ZFS Install](scripts/zfs/install)
  * Added asking for keymap
  * Added asking for locale
  * Added asking to configure networking
  * Added asking to configure dns
* This [CHANGELOG](CHANGELOG.md)

### Changed

* Updated [README.md](README.nd)
* [ZFS Install](scripts/zfs/install)
  * Added switch to either install amd or intel ucode
  * Added check to only configure intel gpu modules when intel gpu is on the system
  * Moved installation of `iwd` and `wpa_supplicant` into section "configure networking"

