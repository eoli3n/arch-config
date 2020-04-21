#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Sort mirrors
print "Sort mirrors"
pacman -Sy reflector --noconfirm
reflector --country France --country Germany --latest 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install
print "Install Archlinux"
pacstrap /mnt base linux linux-firmware btrfs-progs ansible git snapper

# Generate Fstab
print "Generate fstab"
genfstab -U /mnt >> /mnt/etc/fstab

# Set hostname
echo "Please enter hostname :"
read hostname
echo $hostname > /mnt/etc/hostname

# Configure /etc/hosts
print "Configure hosts file"
cat > /etc/hosts <<EOF
#<ip-address>	<hostname.domain.org>	<hostname>
127.0.0.1	    localhost   	        $hostname
::1   		    localhost              	$hostname
EOF

# Prepare locales and keymap
print "Prepare locales and keymap"
echo "KEYMAP=fr" > /mnt/etc/vconsole.conf
sed -i 's/#\(fr_FR.UTF-8\)/\1/' /mnt/etc/locale.gen
echo 'LANG="fr_FR.UTF-8"' > /mnt/etc/locale.conf

# Prepare initramfs
print "Prepare initramfs"
cat > /mnt/etc/mkinitcpio.conf <<"EOF"
MODULES=()
BINARIES=(/usr/bin/btrfs)
FILES=()
HOOKS=(base systemd autodetect modconf block keyboard sd-vconsole sd-encrypt fsck filesystems)
COMPRESSION="lz4"
EOF

# Chroot and configure
print "Chroot and configure system"

arch-chroot /mnt /bin/bash -xe <<"EOF"

  # Sync clock
  hwclock --systohc

  # Generate locale
  locale-gen
  source /etc/locale.conf

  # Generate Initramfs
  mkinitcpio -p linux

  # Install grub2
  pacman -S grub efibootmgr grub-btrfs --noconfirm
  sed -i 's/#\(GRUB_ENABLE_CRYPTODISK=y)/\1/' /etc/default/grub
  grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
  mkdir -p /efi/EFI/boot
  cp /efi/EFI/GRUB/grubx64.efi /efi/EFI/boot/bootx64.efi
  grub-mkconfig -o /boot/grub/grub.cfg

EOF

# Set root passwd
print "Set root password"
arch-chroot /mnt /bin/passwd

# Create user
print "Create user"
arch-chroot /mnt /usr/bin/useradd -m user

# Umount all parts
umount -R /mnt

# Finish
echo -e "\e[32mAll OK"
