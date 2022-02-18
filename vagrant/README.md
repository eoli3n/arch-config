# Using vagrant

## Run

It will automatically download latest archlinux iso in /tmp and use it.

```bash
# Run
$ vagrant plugin install vagrant-libvirt
$ vagrant up archlinux
```

## Remove

``destroy`` subcommand will automatically remove the iso file in /tmp

nvram file is not properly removed, you need to remove it manually before destroying.  
https://github.com/vagrant-libvirt/vagrant-libvirt/issues/1371
```bash
$ sudo rm /var/lib/libvirt/qemu/nvram/archlinux-vagrant.fd
$ vagrant destroy archlinux
```
