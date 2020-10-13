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
print "Install Arch Linux"
pacstrap /mnt base base-devel linux linux-firmware intel-ucode btrfs-progs grub efibootmgr grub-btrfs vim git ansible snapper connman wpa_supplicant

# Generate fstab
print "Generate fstab"
genfstab /mnt >> /mnt/etc/fstab

# Generate crypttab
print "Generate crypttab"
cat > /mnt/etc/crypttab <<EOF
# Mount swap re-encrypting it with a fresh key each reboot
swap	/dev/sda2   	/dev/urandom	swap,cipher=aes-xts-plain64,size=256
EOF
cat > /mnt/etc/crypttab.initramfs <<EOF
universe   /dev/sda3  none  discard
EOF

# Set hostname
echo "Please enter hostname :"
read hostname
echo $hostname > /mnt/etc/hostname

# Configure /etc/hosts
print "Configure hosts file"
cat > /mnt/etc/hosts <<EOF
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
MODULES=(i915 intel_agp)
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

  # Set date
  timedatectl set-ntp true
  timedatectl set-timezone Europe/Paris

  # Generate locale
  locale-gen
  source /etc/locale.conf

  # Generate Initramfs
  mkinitcpio -p linux

  # Prepare grub2
  #sed -i 's/#\(GRUB_ENABLE_CRYPTODISK=y\)/\1/' /etc/default/grub

  # Install grub2
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

  # Configure EFI and grub2
  mkdir -p /boot/EFI/boot
  cp /boot/EFI/GRUB/grubx64.efi /boot/EFI/boot/bootx64.efi
  grub-mkconfig -o /boot/grub/grub.cfg

  # Create user
  useradd -m user

EOF

# Set root passwd
print "Set root password"
arch-chroot /mnt /bin/passwd

# Set user passwd
print "Set user password"
arch-chroot /mnt /bin/passwd user

# Configure sudo
cat > /mnt/etc/sudoers <<"EOF"
root ALL=(ALL) ALL
user ALL=(ALL) ALL
Defaults rootpw
EOF

# Configure network
print "Configure network"
cat > /mnt/etc/systemd/network/enoX.network <<"EOF"
[Match]
Name=en*

[Network]
DHCP=ipv4
IPForward=yes

[DHCP]
UseDNS=no
RouteMetric=10
EOF
cat > /mnt/etc/systemd/network/wlX.network <<"EOF"
[Match]
Name=wl*

[Network]
DHCP=ipv4
IPForward=yes

[DHCP]
UseDNS=no
RouteMetric=20
EOF
systemctl enable systemd-networkd --root=/mnt
systemctl disable systemd-networkd-wait-online --root=/mnt

cat > /mnt/etc/connman/main.conf <<"EOF"
[General]
PreferredTechnologies=ethernet,wifi
NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb,ve-,vb-,docker,veth,eth,wlan,vnet
AllowHostnameUpdates = false
AllowDomainnameUpdates = false
SingleConnectedTechnology = true
EOF
systemctl enable connman --root=/mnt

# Configure DNS
rm /mnt/etc/resolv.conf
arch-chroot /mnt ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved --root=/mnt

# Configure TRIM
systemctl enable fstrim.timer --root=/mnt

# Umount all parts
umount -R /mnt

# Finish
echo -e "\e[32mAll OK"
