#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

print "Load ZFS module"
modprobe zfs

print "Import zpool"
zpool import -d /dev/disk/by-id -R /mnt -l zroot

print "Mount slash dataset"
zfs mount zroot/ROOT/default

print "Enable SWAP"
swapon /dev/zvol/zroot/swap

print "Mount EFI part"
mount /dev/sda1 /mnt/boot

# Finish
echo -e "\e[32mAll OK"
