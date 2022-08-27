#!/usr/bin/env bash
####
# Simple script to automate the steps from
#   https://wiki.archlinux.org/index.php/ZFS#Installation
####
# @since 2022-08-22
# @author:
#   eoli3n <https://eoli3n.eu.org/about/>
#   stev leibelt <artodeto@bazzline.net>
####

set -e

exec &> >(tee "install.log")

# Debug
if [[ "$1" == "debug" ]]
then
    set -x
    debug=1
fi

ask () {
    read -p "> $1 " -r
    echo
}

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
    if [[ -n "$debug" ]]
    then
      read -rp "press enter to continue"
    fi
}

#bo: sourcing install configuration files
if [[ -f install.dist.conf ]];
then
  . install.dist.conf
fi

if [[ -f install.conf ]];
then
  . install.conf
fi
#bo: sourcing install configuration files

if [[ -z ${install_configuration_sourced+x} ]];
then
  echo ":: No configuration file sourced."
  echo "   This is super bad, neither >>install.dist.conf<< nor >>install.conf<< exists."
  echo "   Please run >>01-configure.sh<<."

  exit 1
fi

# Root dataset
root_dataset=$(cat /tmp/root_dataset)

# Sort mirrors
print ":: Sort mirrors"
systemctl start reflector

# Install
if grep -i -q amd < /proc/cpuinfo;
then
  microcode_package='amd-ucode'
else
  microcode_package='intel-ucode'
fi

print ":: Install Arch Linux"
pacstrap /mnt         \
  base                \
  base-devel          \
  bash-completion     \
  $kernel             \
  $kernel-headers     \
  linux-firmware      \
  $microcode_package  \
  efibootmgr          \
  vim                 \
  git                 \
  ansible

# Generate fstab excluding ZFS entries
print ":: Generate fstab excluding ZFS entries"
genfstab -U /mnt | grep -v "$zpoolname" | tr -s '\n' | sed 's/\/mnt//'  > /mnt/etc/fstab
 
# Set hostname
# Configure /etc/hosts
print ":: Configure hosts file"
  cat > /mnt/etc/hosts <<EOF
  #<ip-address>	<hostname.domain.org>	<hostname>
  127.0.0.1	    localhost   	        $hostname
  ::1   		    localhost             $hostname
EOF

# Prepare keymap
echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf

# Prepare locales
sed -i 's/#\('"$locale"'.UTF-8\)/\1/' /mnt/etc/locale.gen
echo 'LANG="'"$locale"'.UTF-8"' > /mnt/etc/locale.conf

# Prepare initramfs
print ":: Prepare initramfs"
if lspci | grep ' VGA ' | grep -q -i intel
then
  modules="i915 intel_agp"
else
  modules=""
fi
cat > /mnt/etc/mkinitcpio.conf <<EOF
MODULES=($modules)
BINARIES=()
FILES=(/etc/zfs/$zpoolname.key)
HOOKS=(base udev autodetect modconf block keyboard keymap zfs filesystems)
COMPRESSION="zstd"
EOF

if [[ $kernel = "linux-lts" ]];
then
  cat > /mnt/etc/mkinitcpio.d/linux-lts.preset <<"EOF"
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-lts"
PRESETS=('default')
default_image="/boot/initramfs-linux-lts.img"
EOF
else
  cat > /mnt/etc/mkinitcpio.d/linux.preset <<"EOF"
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_image="/boot/initramfs-linux.img"
EOF
fi

print ":: Copy ZFS files"
cp /etc/hostid /mnt/etc/hostid
cp /etc/zfs/zpool.cache /mnt/etc/zfs/zpool.cache
cp /etc/zfs/$zpoolname.key /mnt/etc/zfs

### Configure username
if [[ -d /mnt/home/$user ]];
then
  ask "User exists, delete it? (y|N)"

  if [[ ${REPLY} =~ ^[Yy]$ ]];
  then
    arch-chroot /mnt /bin/bash -xe "userdel $user"
    rm -fr /mnt/home/$user
  fi
fi

print ":: Configure timezone"
timedatectl set-ntp true

# Chroot and configure
print ":: Chroot and configure system"

arch-chroot /mnt /bin/bash -xe <<EOF

  ### Reinit keyring
  # As keyring is initialized at boot, and copied to the install dir with pacstrap, and ntp is running
  # Time changed after keyring initialization, it leads to malfunction
  # Keyring needs to be reinitialised properly to be able to sign archzfs key.
  rm -Rf /etc/pacman.d/gnupg
  pacman-key --init
  pacman-key --populate archlinux
  pacman-key --recv-keys F75D9D76 --keyserver keyserver.ubuntu.com
  pacman-key --lsign-key F75D9D76
  pacman -S archlinux-keyring --noconfirm
  # https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs

  #### Check if an archzfs entries exists alreads in /etc/pacman.conf
  # We only want to add it once
  if ! grep -q 'archzfs' < /etc/pacman.conf;
  then
    cat >> /etc/pacman.conf <<"EOSF"
[archzfs]
# Origin Server - France
Server = http://archzfs.com/archzfs/x86_64
# Mirror - Germany
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
# Mirror - Germany
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
# Mirror - India
Server = https://mirror.in.themindsmaze.com/archzfs/archzfs/x86_64
# Mirror - US
Server = https://zxcvfdsa.com/archzfs/archzfs/x86_64
EOSF
  fi
  pacman -Syu --noconfirm zfs-dkms zfs-utils

  # Set date
  ln -sf /usr/share/zoneinfo/$timezone /etc/localtime

  # Sync clock
  hwclock --systohc

  # Generate locale
  locale-gen
  source /etc/locale.conf
  
  # Set keyboard layout
  echo "KEYMAP=$keymap" > /etc/vconsole.conf

  # Generate Initramfs
  mkinitcpio -P

  # Install ZFSBootMenu and deps
  git clone --depth=1 https://github.com/zbm-dev/zfsbootmenu/ /tmp/zfsbootmenu
  pacman -S cpanminus kexec-tools fzf util-linux --noconfirm
  cd /tmp/zfsbootmenu
  make
  make install
  cpanm --notest --installdeps .

  # Create user
  useradd -m $user

EOF

# Set root passwd
print ":: Set root password"
arch-chroot /mnt /bin/passwd

# Set user passwd
print ":: Set user password"
arch-chroot /mnt /bin/passwd "$user"

# Configure sudo
print ":: Configure sudo"
cat > /mnt/etc/sudoers <<EOF
root ALL=(ALL) ALL
$user ALL=(ALL) ALL
Defaults rootpw
EOF

# Configure network
if [[ $configure_network -eq 1 ]];
then
  pacstrap /mnt         \
    networkmanager

  systemctl enable NetworkManager.service --root=/mnt
elif [[ $configure_network -eq 0 ]];
then
  pacstrap /mnt         \
    iwd                 \
    wpa_supplicant

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

  mkdir /mnt/etc/iwd
  cat > /mnt/etc/iwd/main.conf <<"EOF"
[General]
UseDefaultInterface=true
EnableNetworkConfiguration=true
EOF
    systemctl enable iwd --root=/mnt
else
  echo ":: No network configured!"
  echo "   You have to do it manually or you wont have any network that easily on your new installed arch linux."
fi

# Configure DNS
if [[ $configure_dns -eq 1 ]];
then
  rm /mnt/etc/resolv.conf
  ln -s /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf
  sed -i 's/^#DNS=.*/DNS=1.1.1.1/' /mnt/etc/systemd/resolved.conf
  systemctl enable systemd-resolved --root=/mnt
fi

# Configure display manager
if [[ $configure_displaymanager = "kde" ]];
then
#@see
#   https://wiki.archlinux.org/title/Xorg#Installation
#   https://wiki.archlinux.org/title/KDE#Installation
#   https://wiki.archlinux.org/title/SDDM#Installation
  pacstrap /mnt         \
    xorg-server         \
    xorg-apps           \
    plasma-meta         \
    kde-applications

    systemctl enable sddm.service --root=/mnt
fi

# Activate zfs
print ":: Configure ZFS"
systemctl enable zfs-import-cache --root=/mnt
systemctl enable zfs-mount --root=/mnt
systemctl enable zfs-import.target --root=/mnt
systemctl enable zfs.target --root=/mnt

# Configure zfs-mount-generator
print ":: Configure zfs-mount-generator"
mkdir -p /mnt/etc/zfs/zfs-list.cache
touch /mnt/etc/zfs/zfs-list.cache/$zpoolname
zfs list -H -o name,mountpoint,canmount,atime,relatime,devices,exec,readonly,setuid,nbmand | sed 's/\/mnt//' > /mnt/etc/zfs/zfs-list.cache/$zpoolname
systemctl enable zfs-zed.service --root=/mnt

# Configure zfsbootmenu
mkdir -p /mnt/efi/EFI/ZBM

# Generate zfsbootmenu efi
print ":: Configure zfsbootmenu"
# https://github.com/zbm-dev/zfsbootmenu/blob/master/etc/zfsbootmenu/mkinitcpio.conf

cat > /mnt/etc/zfsbootmenu/mkinitcpio.conf <<"EOF"
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect modconf block keyboard keymap)
COMPRESSION="zstd"
EOF

cat > /mnt/etc/zfsbootmenu/config.yaml <<EOF
Global:
  ManageImages: true
  BootMountPoint: /efi
  InitCPIO: true

Components:
  Enabled: false
EFI:
  ImageDir: /efi/EFI/ZBM
  Versions: false
  Enabled: true
Kernel:
  CommandLine: ro quiet loglevel=0 zbm.import_policy=hostid
  Prefix: vmlinuz
EOF

# Set cmdline
zfs set org.zfsbootmenu:commandline="rw quiet nowatchdog rd.vconsole.keymap=$keymap" $zpoolname/ROOT/"$root_dataset"

# Generate ZBM
print ":: Generate zbm"
arch-chroot /mnt /bin/bash -xe <<"EOF"

  # Export locale
  export LANG="$locale"

  # Generate zfsbootmenu
  generate-zbm
EOF

# Set DISK
if [[ -f /tmp/disk ]]
then
  DISK=$(cat /tmp/disk)
else
  print ":: Select the disk you installed on:"
  select ENTRY in $(ls /dev/disk/by-id/);
  do
      DISK="/dev/disk/by-id/$ENTRY"
      echo "Creating boot entries on $ENTRY."
      break
  done
fi

# Create UEFI entries
print ":: Create efi boot entries"
if ! efibootmgr | grep ZFSBootMenu
then
    efibootmgr --disk "$DISK" \
      --part 1 \
      --create \
      --label "ZFSBootMenu Backup" \
      --loader "\EFI\ZBM\vmlinuz-backup.efi" \
      --verbose
    efibootmgr --disk "$DISK" \
      --part 1 \
      --create \
      --label "ZFSBootMenu" \
      --loader "\EFI\ZBM\vmlinuz.efi" \
      --verbose
else
    print ":: Boot entries already created"
fi

# Umount all parts
print ":: Umount all parts"
umount /mnt/efi
zfs umount -a

# Export zpool
print ":: Export zpool"
zpool export $zpoolname

# Finish
echo -e "\e[32mAll OK"
