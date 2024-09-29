#!/bin/bash

if [[ $# -ne 1 ]]
then
  echo "usage: ./monitor.sh [container_name]"
  exit 1;
fi

container_name=$1

tail -F /var/lib/lxc/"$container_name"/var/log/auth.log | while read line
  do
    if echo "$line" | grep -q "session opened";
    then
      # Additionally run a script to monitor inactivity
      sleep 30m
      pkill -P $$ tail # Kill the tail process
      break # No longer need to monitor for ssh connection, thus concluding the script
    fi
done
