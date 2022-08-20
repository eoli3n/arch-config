#!/usr/bin/env bash
####
# Simple script prepare system for zfs installation
####
# @since 2022-08-22
# @author:
#   eoli3n <https://eoli3n.eu.org/about/>
#   stev leibelt <artodeto@bazzline.net>
####

set -e

exec &> >(tee "configure.log")

print () {
    echo -e "\n\033[1m> $1\033[0m\n"
}

ask () {
    read -p "> $1 " -r
    echo
}

menu () {
    PS3="> Choose a number: "
    select i in "$@"
    do 
        echo "$i"
        break
    done
}

# Tests
tests () {
    ls /sys/firmware/efi/efivars > /dev/null &&   \
        ping archlinux.org -c 1 > /dev/null &&    \
        timedatectl set-ntp true > /dev/null &&   \
        modprobe zfs &&                           \
        print "Tests ok"
}

select_disk () {
    # Set DISK
    select ENTRY in $(ls /dev/disk/by-id/);
    do
        DISK="/dev/disk/by-id/$ENTRY"
        echo "$DISK" > /tmp/disk
        echo "Installing on $ENTRY."
        break
    done
}

wipe () {
    ask "Do you want to wipe all datas on $ENTRY ?"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Clear disk
        dd if=/dev/zero of="$DISK" bs=512 count=1
        wipefs -af "$DISK"
        sgdisk -Zo "$DISK"
    fi
}

partition () {
    # EFI part
    print "Creating EFI part"
    sgdisk -n1:1M:+512M -t1:EF00 "$DISK"
    EFI="$DISK-part1"
    
    # ZFS part
    print "Creating ZFS part"
    sgdisk -n3:0:0 -t3:bf01 "$DISK"
    
    # Inform kernel
    partprobe "$DISK"
    
    # Format efi part
    sleep 1
    print "Format EFI part"
    mkfs.vfat "$EFI"
}

zfs_passphrase () {
    # Generate key
    print "Set ZFS passphrase"
    read -r -p "> ZFS passphrase: " -s pass
    echo
    echo "$pass" > /etc/zfs/zroot.key
    chmod 000 /etc/zfs/zroot.key
}

create_pool () {
    # ZFS part
    ZFS="$DISK-part3"
    
    # Create ZFS pool
    print "Create ZFS pool"
    zpool create -f -o ashift=12                          \
                 -o autotrim=on                           \
                 -O acltype=posixacl                      \
                 -O compression=zstd                      \
                 -O relatime=on                           \
                 -O xattr=sa                              \
                 -O dnodesize=legacy                      \
                 -O encryption=aes-256-gcm                \
                 -O keyformat=passphrase                  \
                 -O keylocation=file:///etc/zfs/zroot.key \
                 -O normalization=formD                   \
                 -O mountpoint=none                       \
                 -O canmount=off                          \
                 -O devices=off                           \
                 -R /mnt                                  \
                 zroot "$ZFS"
}

create_root_dataset () {
    # Slash dataset
    print "Create root dataset"
    zfs create -o mountpoint=none                 zroot/ROOT

    # Set cmdline
    zfs set org.zfsbootmenu:commandline="ro quiet" zroot/ROOT
}

create_system_dataset () {
    print "Create slash dataset"
    zfs create -o mountpoint=/ -o canmount=noauto zroot/ROOT/"$1"

    # Generate zfs hostid
    print "Generate hostid"
    zgenhostid
    
    # Set bootfs 
    print "Set ZFS bootfs"
    zpool set bootfs="zroot/ROOT/$1" zroot

    # Manually mount slash dataset
    zfs mount zroot/ROOT/"$1"
}

create_home_dataset () {
    print "Create home dataset"
    zfs create -o mountpoint=/ -o canmount=off zroot/data
    zfs create                                 zroot/data/home
}

export_pool () {
    print "Export zpool"
    zpool export zroot
}

import_pool () {
    print "Import zpool"
    zpool import -d /dev/disk/by-id -R /mnt zroot -N -f
    zfs load-key zroot
}

mount_system () {
    print "Mount slash dataset"
    zfs mount zroot/ROOT/"$1"
    zfs mount -a
    
    # Mount EFI part
    print "Mount EFI part"
    EFI="$DISK-part1"
    mkdir -p /mnt/efi
    mount "$EFI" /mnt/efi
}

copy_zpool_cache () {
    # Copy ZFS cache
    print "Generate and copy zfs cache"
    mkdir -p /mnt/etc/zfs
    zpool set cachefile=/etc/zfs/zpool.cache zroot
}

# Main

tests

print "Is this the first install or a second install to dualboot ?"
install_reply=$(menu first dualboot)

select_disk
zfs_passphrase

# If first install
if [[ $install_reply == "first" ]]
then
    # Wipe the disk
    wipe
    # Create partition table
    partition
    # Create ZFS pool
    create_pool
    # Create root dataset
    create_root_dataset
fi

ask "Name of the slash dataset ?"
name_reply="$REPLY"
echo "$name_reply" > /tmp/root_dataset

if [[ $install_reply == "dualboot" ]]
then
    import_pool
fi

create_system_dataset "$name_reply"

if [[ $install_reply == "first" ]]
then
    create_home_dataset
fi

export_pool
import_pool
mount_system "$name_reply"
copy_zpool_cache

#bo: configuration section
# By sourcing an existing file before asking the question, we can easily extend the questions/variables
#   or use pre configured install.conf files but configure all missing variables

install_conf="install.conf"

if [[ -f ${install_conf} ]];
then
  echo ":: Sourcing >>${install_conf}<<."
  echo "   You where only asked questions for not existing configuration values."
  echo "   If you want to configure things in total, please remove >>${install_conf}<<."

  . ${install_conf}
fi

##c
if [[ -z ${configure_dns+x} ]];
then
  ask "Configure DNS? (y|N)"

  if [[ $REPLY =~ ^[Yy]$ ]];
  then
    echo "configure_dns=1" >> $install_conf
  fi
fi

if [[ -z ${configure_network+x} ]];
then
  ask "Configure networking? (y|N)"
  if [[ $REPLY =~ ^[Yy]$ ]];
  then
    echo "Which network-provider?"
    ask "0) iwd + wpa_supplicant   1) networkmanager"

    echo "configure_network=\"${REPLY}\"" >> $install_conf
  fi
fi

##h
if [[ -z ${hostname+x} ]];
then
  read -r -p 'Please enter hostname : ' hostname
  echo "$hostname" > /mnt/etc/hostname

  echo "hostname=\"${hostname}\"" >> $install_conf
fi

##k
if [[ -z ${kernel+x} ]];
then
  echo ":: Which kernel?"
  ask "0) linux-lts   1) linux?"

  if [[ ${REPLY} -eq 1 ]];
  then
    kernel="linux"
  else
    kernel="linux-lts"
  fi

  echo "kernel=\"${kernel}\"" >> $install_conf
fi

if [[ -z ${keymap+x} ]];
then
  print ":: Prepare locales and keymap"
  echo "Which keymap do you want to use?"
  ask "0) fr   1) de-latin1   2) input your own"

  case ${REPLY} in
    0)
      keymap="fr"
      ;;
    1)
      keymap="de-latin1"
      ;;
    2)
      ask "Please insert your keymap"
      keymap="${REPLY}"
      ;;
    *)
      keymap="fr"
      ;;
  esac
  echo "keymap=\"${keymap}\"" >> $install_conf
fi

##l
if [[ -z ${locale+x} ]];
then
  echo "Which locales to use?"
  ask "0) fr_FR   1) de_DE   2) input your own"

  case ${REPLY} in
    0)
      locale="fr_FR"
      ;;
    1)
      locale="de_DE"
      ;;
    2)
      ask "Please insert your keymap"
      locale="${REPLY}"
      ;;
    *)
      locale="fr_FR"
      ;;
  esac

  echo "locale=\"${locale}\"" >> $install_conf
fi

##t
if [[ -z ${timezone+x} ]];
then
  echo "What is your timezone?"
  ask "0) Europe/Paris   1) Europe/Berlin   2) input your own"

  case ${REPLY} in
    0)
      timezone="Europe/Paris"
      ;;
    1)
      timezone="Europe/Berlin"
      ;;
    2)
      ask "Please insert your keymap"
      timezone="${REPLY}"
      ;;
    *)
      timezone="Europe/Paris"
      ;;
  esac

  echo "timezone=\"${timezone}\"" >> $install_conf
fi

##u
if [[ -z ${user+x} ]];
then
  ask "Please input your username"
  user="${REPLY}"

  echo "user=\"${user}\"" >> $install_conf
fi

##z
if [[ -z ${zpoolname+x} ]];
then
  ask "Please input zpool name. Default is >>zroot<<."
  zpoolname="${REPLY:-zroot}"

  echo "zpoolname=\"${zpoolname}\"" >> $install_conf
fi
#eo: configuration section

# Finish
echo -e "\e[32mAll OK"
