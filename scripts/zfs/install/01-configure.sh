#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Tests
ls /sys/firmware/efi/efivars > /dev/null && \
  ping archlinux.org -c 1 > /dev/null &&    \
  timedatectl set-ntp true > /dev/null &&   \
  print "Tests ok"

# Test to load zfs module
modprobe zfs

# Set DISK
select ENTRY in $(ls /dev/disk/by-id/);
do
    DISK="/dev/disk/by-id/$ENTRY"
    echo "Installing on $ENTRY."
    break
done

read -p "> Do you want to wipe all datas on $ENTRY ?" -n 1 -r
echo # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Clear disk
    dd if=/dev/zero of=$DISK bs=512 count=1
    wipefs -af $DISK
    sgdisk -Zo $DISK
fi

# EFI part
print "Creating EFI part"
sgdisk -n1:1M:+512M -t1:EF00 $DISK
EFI=$DISK-part1

# ZFS part
print "Creating ZFS part"
sgdisk -n3:0:0 -t3:bf01 $DISK
ZFS=$DISK-part3

# Inform kernel
partprobe $DISK

# Format boot part
sleep 1
print "Format EFI part"
mkfs.vfat $EFI

# Create ZFS pool
print "Create ZFS pool"
zpool create -f -o ashift=12           \
             -o autotrim=on            \
             -O acltype=posixacl       \
             -O compression=zstd       \
             -O relatime=on            \
             -O xattr=sa               \
             -O dnodesize=legacy       \
             -O encryption=aes-256-gcm \
             -O keyformat=passphrase   \
             -O keylocation=prompt     \
             -O normalization=formD    \
             -O mountpoint=none        \
             -O canmount=off           \
             -O devices=off            \
             -R /mnt                   \
             zroot $ZFS

# Slash dataset
print "Create slash dataset"
zfs create -o mountpoint=none                               zroot/ROOT
zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/default 

# Manually mount slash dataset
zfs mount zroot/ROOT/default

# Home dataset
print "Create home dataset"
zfs create -o mountpoint=/ -o canmount=off zroot/data
zfs create                                 zroot/data/home
zfs create -o mountpoint=/root             zroot/data/home/root

# SWAP
#print "Create swap dataset"
#zfs create -V 8G -b $(getconf PAGESIZE)         \
#           -o logbias=throughput -o sync=always \
#           -o primarycache=metadata             \
#           -o com.sun:auto-snapshot=false       \
#           zroot/swap

# Specific datasets
print "Create specific datasets excluded from snapshots"
zfs create -o mountpoint=/var -o canmount=off     zroot/var
zfs create                                        zroot/var/log
zfs create -o mountpoint=/var/lib -o canmount=off zroot/var/lib
zfs create                                        zroot/var/lib/libvirt
zfs create                                        zroot/var/lib/docker

# Set bootfs 
print "Set ZFS bootfs"
zpool set bootfs="zroot/ROOT/default" zroot

# Export and reimport zpool
print "Export and reimport zpool"
zpool export zroot
zpool import -d /dev/disk/by-id -R /mnt zroot -N
zfs load-key zroot
zfs mount zroot/ROOT/default
zfs mount -a

# Enable SWAP
#print "Enable SWAP"
#mkswap -f /dev/zvol/zroot/swap
#swapon /dev/zvol/zroot/swap

# Mount EFI part
print "Mount EFI part"
mkdir /mnt/efi
mount $EFI /mnt/efi

# Prepare zectl
print "Prepare zectl"
mkdir -p /mnt/efi/env/org.zectl-default
mkdir /mnt/boot
mount --bind /mnt/efi/env/org.zectl-default /mnt/boot

# Copy ZFS cache
print "Generate and copy zfs cache"
mkdir -p /mnt/etc/zfs
zpool set cachefile=/etc/zfs/zpool.cache zroot
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache

# Finish
echo -e "\e[32mAll OK"
