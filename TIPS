# External snapshot with virsh (RAM only)
sudo virsh snapshot-create-as --domain archlinux zfs-module --memspec file=/mnt/cle/snapshots/mem-state1.qcow2,snapshot=external --atomic

# To restore, shutdown VM
sudo virsh restore /mnt/cle/snapshots/mem-state1.qcow2
