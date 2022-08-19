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

* zfs install
  * added asking for zpool name
  * added asking for keymap
  * added asking for locale
  * added asking for timezone
  * added asking to configure networking
  * added asking to configure dns
  * added asking for kernel (`linux` or `linux-lts`)
  * added usage of install.conf file to ease up multiple runs of the script (yep, perfect if you have to develop this script)
  * added support for networkmanager configuration
  * added prefix of >>:: << on each `print`-output
  * added automatic detection of ucode package file (currently only amd and intel are supported)
* this changelog

### Changed

* zfs install
  * added switch to either install amd or intel ucode
  * added check to only configure intel gpu modules when intel gpu is on the system
  * moved installation of `iwd` and `wpa_supplicant` into section "configure networking"
