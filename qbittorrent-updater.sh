#!/bin/bash

remote_version=$(curl  https://api.github.com/repos/Madagambada/qbittorrent-nox-builder/tags -s | grep name | sed 's/    "name":\ "//' | sed 's/",//' | sort -V | tail -1)
local_version=$(qbittorrent-nox -v | sed 's/.*v//')

if [ $remote_version != $local_version ]; then
  wget -q https://github.com/Madagambada/qbittorrent-nox-builder/releases/download/$remote_version/qbittorrent-nox_$remote_version-1_i386.deb

  dpkg -x qbittorrent-nox_$remote_version-1_i386.deb new
  dpkg -e qbittorrent-nox_$remote_version-1_i386.deb new/DEBIAN
  #Change madagambada so that it fits your username
  sed -i 's/#User=/User=madagambada/g' new/etc/systemd/system/qbittorrent-nox.service
  dpkg-deb --build new

  systemctl stop qbittorrent-nox

  apt install new.deb -y
  rm qbittorrent-nox_$remote_version-1_i386.deb new new.deb

  systemctl --system daemon-reload
  systemctl enable qbittorrent-nox
  systemctl start qbittorrent-nox
fi
