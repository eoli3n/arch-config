#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Set DISK
select ENTRY in $(ls /dev/disk/by-id/);
do
    DISK="/dev/disk/by-id/$ENTRY"
    echo "Mounting $ENTRY."
    break
done

print "Load ZFS module"
modprobe zfs

print "Reimport zpool"
if zpool status zroot &>/dev/null
then
  zpool export zroot
fi
zpool import -d /dev/disk/by-id -R /mnt zroot -N -f

print "Load ZFS keys"
zfs load-key -L prompt zroot

print "Mount ROOT dataset"
select ENTRY in $(zfs list | awk '/ROOT\// {print $1}')
do
    echo "Mount $ENTRY as slash dataset."
    zfs mount "$ENTRY"
    break
done

print "Mount other datasets"
zfs mount -a

print "Mount EFI part"
EFI="$DISK-part1"
mount "$EFI" /mnt/efi

# Finish
echo -e "\e[32mAll OK"
