#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Sort mirrors
print "Sort mirrors"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

# Install
pacstrap /mnt base linux linux-firmware btrfs-progs ansible git

# Generate Fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot
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


