#!/bin/bash

email=""
username=""
pw=""
repo=""

cd /mnt/pihole-backup

if [ ! -d ".git" ]; then
 git clone https://$username:$pw@$repo .
fi

/usr/local/bin/pihole -a -t
tar xzf pi-hole-*
rm *.tar.gz

git add *
status=$(git status)

if [[ $status == *"Changes"* ]]; then
 git config user.email "$email"
 git config user.name "$username"
 git commit -a -m "Auto backup"
 git push https://$username:$pw@$repo
fi
