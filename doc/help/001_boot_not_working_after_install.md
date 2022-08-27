# Boot not working after install

## Issue

It can happen that an older entry in your efibootmenu is preventing zfsbootmenu to work.

## Solution

Use `efibootmgr` to remove all unneeded boot entries

```bash
#list existing entries
efibootmgr

#delete number until all unneeded are removed
efibootmgr --delete-bootnum --bootnum <xxxx>
```

Rerun the installation and all should be fine.

## Links

* [Issue/5 - Boot not working after install](https://github.com/eoli3n/arch-config/issues/5) - 20220814

