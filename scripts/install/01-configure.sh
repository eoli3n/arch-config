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

# SWAP part
print "Creating encrypted SWAP part"
sgdisk -n2:0:+8G -t2:8308 $DISK
SWAP=$DISK-part2

# LUKS part
print "Creating LUKS part"
sgdisk -n3:0:0 -t3:8309 $DISK
LUKS=$DISK-part3

# Inform kernel
partprobe $DISK

# Format boot part
sleep 1
print "Format EFI part"
mkfs.vfat $EFI

# Create plain encrypted SWAP
print "Create encrypted SWAP"
cryptsetup open --type plain $SWAP swap
ESWAP=/dev/mapper/swap
mkswap $ESWAP
swapon $ESWAP

# Create LUKS
print "Create LUKS"
# https://savannah.gnu.org/bugs/?55093
cryptsetup -v --type luks1 --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --verify-passphrase luksFormat $LUKS
cryptsetup luksOpen $LUKS universe
BTRFS=/dev/mapper/universe

# Format BTRFS part
print "Format BTRFS"
mkfs.btrfs -L "Sun" $BTRFS

# Create BTRFS subvolumes
print "Create subvolumes"
mount -t btrfs -o autodefrag,noatime $BTRFS /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots

# Exclude some path from / subvolume
# https://en.opensuse.org/SDB:BTRFS#Default_Subvolumes
btrfs subvolume create /mnt/var
btrfs subvolume create /mnt/tmp
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/opt
btrfs subvolume create /mnt/srv

# Mount filesystems
# https://docs.google.com/spreadsheets/d/1x9-3OQF4ev1fOCrYuYWt1QmxYRmPilw_nLik5H_2_qA/edit#gid=0
umount /mnt
print "Mount parts"
mount -o autodefrag,noatime,subvol=@,compress=zstd:1 $BTRFS /mnt
mkdir /mnt/home
mount -o autodefrag,noatime,subvol=@home,compress=zstd:1 $BTRFS /mnt/home
mkdir /mnt/.snapshots
mount -o autodefrag,noatime,subvol=@snapshots,compress=zstd:1 $BTRFS /mnt/.snapshots
mkdir /mnt/boot
mount $EFI /mnt/boot

# Finish
echo -e "\e[32mAll OK"
