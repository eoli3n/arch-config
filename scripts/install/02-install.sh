#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Sort mirrors
print "Sort mirrors"
pacman -Sy pacman-contrib --noconfirm
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
print "Sorting..."
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

# Install
print "Install Archlinux"
pacstrap /mnt base linux linux-firmware btrfs-progs ansible git

# Generate Fstab
print "Generate fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
print "Chroot and configure system"
arch-chroot /mnt /bin/bash -e <<EOF
  
  # Set hostname

  # Sync clock
  hwclock --systohc

  # Generate locale

  # Keymap layout
  echo "KEYMAP=fr" > /etc/vconsole.conf

  # Generate Initramfs
  mkinitcpio -p linux

  # Set root passwd
  passwd

  # Install grub2

  # Create user

EOF


