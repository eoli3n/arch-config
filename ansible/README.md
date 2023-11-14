### Run ansible

1. Install ansible with pacman package
2. Run
```
git clone --recursive https://github.com/eoli3n/arch-config
cd arch-config/ansible
ansible-playbook install-{zfs,btrfs}.yml -K
```
3. Remove ansible pacman package
