#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Import zpool
print "Import zpool"
zpool import -d /dev/disk/by-id -R /mnt -l zroot

# Enable SWAP
print "Enable SWAP"
mkswap -f /dev/zvol/zroot/swap
swapon /dev/zvol/zroot/swap

# Mount EFI part
print "Mount EFI part"
mkdir /mnt/boot
mount $EFI /mnt/boot

# Mount home part
print "Mount EFI part"
mkdir /mnt/home
mount -t zfs zroot/data/home /mnt/home

# Finish
echo -e "\e[32mAll OK"
