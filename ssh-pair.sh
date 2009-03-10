#!/bin/sh
default_host=hal.hunch.se
#----------------------------------
read -p "(user@)hostname to pair with ($default_host): " host
if [ "$host" == "" ]; then
  host=$default_host
fi
use_existing=n
if [ -f ~/.ssh/id_rsa.pub ]; then
  read -p "Use existing ~/.ssh/id_rsa.pub? (Y/n): " -n 1 use_existing
  echo
fi
if [ "$use_existing" = "n" ] || [ "$use_existing" = "N" ]; then
  ssh-keygen -t rsa || exit 1
elif [ "$use_existing" != "y" ] && [ "$use_existing" != "Y" ] && [ "$use_existing" != "" ]; then
  echo "$0: Invalid answer $use_existing -- expected \"y\" or \"n\"." >&2
  exit 1
fi
ssh $host "mkdir -pm 0700 ~/.ssh && echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys"
