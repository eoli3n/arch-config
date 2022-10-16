#!/bin/bash
# Workaround to detect aur submodule library with pre-commit

CURRENT_DIR=$(dirname "$0")
cd "$CURRENT_DIR"/.. || exit 1
ansible-playbook --syntax-check install-zfs.yml
