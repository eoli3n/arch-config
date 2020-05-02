#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

print "Import zpool"
zpool import -d /dev/disk/by-id -R /mnt -l zroot

print "Enable SWAP"
swapon /dev/zvol/zroot/swap

print "Mount EFI part"
mount $EFI /mnt/boot

print "Mount home part"
mount -t zfs zroot/data/home /mnt/home

# Finish
echo -e "\e[32mAll OK"
