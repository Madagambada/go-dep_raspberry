#!/bin/bash

remote_version=$(curl  https://api.github.com/repos/cloudflare/cloudflared/tags -s | grep name | sed 's/    "name":\ "//' | sed 's/",//' | sort -V | tail -1)
local_version=$(cloudflared -v | sed 's/.*n //' | sed 's/ (.*//')

if [ $remote_version != $local_version ]; then
  /usr/local/bin/cloudflared update
  systemctl restart cloudflared
fi
