#!/bin/bash

repo="https://mir.archlinux.fr/iso/latest/"
dest_file="/tmp/archlinux.iso"

if [[ "$1" == start ]]
then
  iso="${repo}$(curl -s ${repo} | grep -Eo 'archlinux-[0-9]{4}\.[0-9]{2}\.[0-9]{2}-x86_64\.iso' | head -n1)"
  if [[ ! -f "$dest_file" ]]
  then
    echo "-> Download latest archlinux iso"
    wget "$iso" --quiet -O "$dest_file"
  fi
elif [[ "$1" == "stop" ]]
then
  echo "-> Delete archlinux iso"
  rm "$dest_file"
else
  echo "Please use $0 [start|stop]"
fi
