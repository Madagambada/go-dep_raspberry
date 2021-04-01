#!/bin/bash

remote_version=$(curl  https://api.github.com/repos/Madagambada/qbittorrent-nox-static-i386/tags -s | grep name | sed 's/    "name":\ "//' | sed 's/",//' | sort -V | tail -1)
if [ -z $remote_version ]
then
  remote_version="0"
fi

if [ -f "/usr/local/bin/qbittorrent-nox" ]
then
  local_version=$(qbittorrent-nox -v | sed 's/.*v//')
else
  local_version="0"
fi

if [ $remote_version != $local_version ]; then
  wget -q https://github.com/Madagambada/qbittorrent-nox-static-i386/releases/download/$remote_version/qbittorrent-nox_$remote_version-1_i386.deb
  
  systemctl stop qbittorrent-nox

  apt install ./qbittorrent-nox_$remote_version-1_i386.deb -y
  rm qbittorrent-nox_$remote_version-1_i386.deb
  
  #Change madagambada so that it fits your username
  sed -i 's/#User=/User=madagambada/g' /etc/systemd/system/qbittorrent-nox.service
  systemctl --system daemon-reload
  systemctl enable qbittorrent-nox
  systemctl start qbittorrent-nox
fi
