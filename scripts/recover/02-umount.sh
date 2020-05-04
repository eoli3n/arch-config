#!/usr/bin/env bash

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

print "Umount /boot"
umount /mnt/boot
umount /mnt/efi

print "Export zpool"
zpool export zroot

# Finish
echo -e "\e[32mAll OK"
