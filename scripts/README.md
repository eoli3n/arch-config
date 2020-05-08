### Scripts to install on different rootfs

For each:

``01-configure.sh`` will 
- Create partition scheme
- Format everything
- Mount partitions

``02-install.sh`` will
- Configure mirrors
- Install Arch Linux and kernel
- Generate initramfs
- Configure hostname, locales, keymap, network
- Install and configure bootloader
- Generate users and passwords
