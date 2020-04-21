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

# Chroot and configure
print "Chroot and configure system"

echo "Please enter hostname :"
read hostname
hostname=$hostname arch-chroot /mnt /bin/bash -e <<"EOF"
  
  # Set hostname
  echo $hostname > /etc/hostname

  # Sync clock
  hwclock --systohc

  # Generate locale
  sed -i 's/#\(fr_FR.UTF-8\)/\1/' /etc/locale.gen
  locale-gen
  echo 'LANG="fr_FR.UTF-8"' > /etc/locale.conf

  # Keymap layout
  echo "KEYMAP=fr" > /etc/vconsole.conf

  # Generate Initramfs
  mkinitcpio -p linux

  # Install grub2
  pacman -S grub efibootmgr grub-btrfs --noconfirm
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
  mkdir -p $boot/EFI/boot
  cp /boot/EFI/grub_uefi/grubx64.efi /boot/EFI/boot/bootx64.efi
  grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Set root passwd
print "Set root password"
arch-chroot /mnt /bin/passwd

# Create user
print "Create user"
