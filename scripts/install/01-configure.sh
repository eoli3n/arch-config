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

# Load ZFS module
print "Load ZFS module"
curl -s https://eoli3n.github.io/archzfs/init | bash

# Create ZFS pool
print "Create ZFS pool"
zpool create -f -o ashift=12           \
             -O acltype=posixacl       \
             -O compression=lz4        \
             -O relatime=on            \
             -O xattr=sa               \
             -O dnodesize=legacy       \
             -O encryption=aes-256-gcm \
             -O keyformat=passphrase   \
             -O keylocation=prompt     \
             -O normalization=formD    \
             -O mountpoint=/ -R /mnt   \
             zroot $ZFS

# Slash dataset
print "Create slash dataset"
zfs create -o mountpoint=none zroot/ROOT
zfs create -o dedup=on -o mountpoint=/ zroot/ROOT/default

# Home dataset
print "Create home dataset"
zfs create -o mountpoint=none zroot/data
zfs create -o dedup=on -o mountpoint=/home zroot/data/home
zfs create -o dedup=on -o mountpoint=/root zroot/data/home/root

# SWAP
print "Create swap dataset"
zfs create -V 8G -b $(getconf PAGESIZE)         \
           -o logbias=throughput -o sync=always \
           -o primarycache=metadata             \
           -o com.sun:auto-snapshot=false       \
           zroot/swap

# /tmp
print "Create /tmp dataset"
zfs create -o setuid=off                  \
           -o devices=off                 \
           -o sync=disabled               \
           -o mountpoint=/tmp             \
           -o com.sun:auto-snapshot=false \
           zroot/tmp

# chmod 1777 /tmp ?

# /var
print "Create datasets snapshot free"
zfs create -o canmount=off -o mountpoint=/var zroot/ROOT/var
zfs create -o canmount=off -o mountpoint=/usr zroot/ROOT/usr
zfs create -o canmount=off -o mountpoint=/srv zroot/ROOT/srv
zfs create                                    zroot/ROOT/var/log

# Set bootfs 
print "Set bootfs"
zpool set bootfs=zroot/ROOT/default zroot

# Enable SWAP
print "Enable SWAP"
mkswap -f /dev/zvol/zroot/swap
swapon /dev/zvol/zroot/swap

# Mount EFI part
print "Mount EFI part"
mkdir /mnt/boot
mount $EFI /mnt/boot

# Finish
echo -e "\e[32mAll OK"
