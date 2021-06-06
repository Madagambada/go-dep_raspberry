#!/bin/bash

email=""
username=""
pw=""
repo=""

echo "Backup pihole configuration"
cd /mnt/pihole-backup
if [ ! -d ".git" ]; then
 git clone https://$username:$pw@$repo .
fi

echo "Generate backup"
/usr/local/bin/pihole -a -t
tar xzf pi-hole-*
rm *.tar.gz

echo "Check for changes"
git add *
status=$(git status)

if [[ $status == *"Changes"* ]]; then
 echo "Push to repo"
 git config user.email "$email"
 git config user.name "$username"
 git commit -a -m "Auto backup"
 git push https://$username:$pw@$repo
else
 echo "No changes in configuration"
fi

