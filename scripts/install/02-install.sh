#!/usr/bin/env bash

set -e

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

# Configure /tmp
#chmod 1777 /mnt/tmp

# Sort mirrors
print "Sort mirrors"
pacman -Sy reflector --noconfirm
reflector --country France --country Germany --latest 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Install
print "Install Archlinux"
pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware intel-ucode efibootmgr vim git ansible connman wpa_supplicant

# Generate fstab
print "Generate fstab"
genfstab -U -p /mnt >> /mnt/etc/fstab

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
MODULES=(i915 intel_agp)
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block keyboard keymap zfs usr filesystems)
COMPRESSION="lz4"
EOF

# Chroot and configure
print "Chroot and configure system"

arch-chroot /mnt /bin/bash -xe <<"EOF"

  # ZFS deps
  cat >> /etc/pacman.conf <<"EOSF"
[archzfs]
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
EOSF
  pacman-key --recv-keys F75D9D76
  pacman-key --lsign-key F75D9D76
  pacman -Syu zfs-linux-lts zfs-utils

  # Sync clock
  hwclock --systohc

  # Set date
  timedatectl set-ntp true
  timedatectl set-timezone Europe/Paris

  # Generate locale
  locale-gen
  source /etc/locale.conf

  # Generate Initramfs
  mkinitcpio -P

  # Install bootloader
  bootctl --path=/boot install

  # Generates boot entries
  mkdir -p /boot/loader/entries
  cat > /boot/loader/loader.conf <<"EOSF"
default archlinux
timeout 10
EOSF
  cat > /boot/loader/entries/archlinux.conf <<"EOSF"
Title "ZFS Archlinux"
linux   /vmlinuz-linux-lts
initrd	/intel-ucode.img
initrd  /initramfs-linux-lts.img
options zfs=zroot/ROOT/default rw
EOSF

  # Update bootloader configuration
  bootctl --path=/boot update

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
print "Configure sudo"
cat > /mnt/etc/sudoers <<"EOF"
root ALL=(ALL) ALL
user ALL=(ALL) ALL
Defaults rootpw
EOF

# Configure network
print "Configure networking"
cat > /mnt/etc/systemd/network/br0.netdev <<"EOF"
[NetDev]
Name=br0
Kind=bridge
EOF
cat > /mnt/etc/systemd/network/br0.network <<"EOF"
[Match]
Name=br0

[Network]
DHCP=ipv4
IPForward=kernel

[DHCP]
UseDNS=true
RouteMetric=10
EOF
cat > /mnt/etc/systemd/network/enoX.network <<"EOF"
[Match]
Name=en*

[Network]
Bridge=br0
IPForward=kernel

[DHCP]
RouteMetric=10
EOF
cat > /mnt/etc/systemd/network/wlX.network <<"EOF"
[Match]
Name=wl*

[DHCP]
RouteMetric=20
EOF
systemctl enable systemd-networkd --root=/mnt

# Configure DNS
print "Configure DNS"
rm /mnt/etc/resolv.conf
arch-chroot /mnt ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
systemctl enable systemd-resolved --root=/mnt

# Configure TRIM
print "Configure TRIM"
systemctl enable fstrim.timer --root=/mnt

# Configure tmp
print "Configure /tmp"
# https://wiki.archlinux.org/index.php/ZFS#/tmp
systemctl mask tmp.mount --root=/mnt

# Activate zfs
print "Configure ZFS"
sudo systemctl enable zfs-import-cache --root=/mnt
sudo systemctl enable zfs-mount --root=/mnt
sudo systemctl enable zfs-import.target --root=/mnt
sudo systemctl enable zfs.target --root=/mnt

# Umount all parts
print "Umount all parts"
umount /mnt/boot
umount /mnt/home
swapoff /dev/zvol/zroot/swap
zfs umount -a

# Export zpool
print "Export zpool"
zpool export zroot

# Finish
echo -e "\e[32mAll OK"
