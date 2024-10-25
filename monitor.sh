#!/bin/bash

if [[ $# -ne 2 ]]
then
  echo "usage: ./monitor.sh [container_name] [external_ip]"
  exit 1
fi

container_name=$1
external_ip=$2

sudo tail -F /var/lib/lxc/"$container_name"/rootfs/var/log/auth.log | while read -r line
  do
    if echo "$line" | grep -q "session opened" ;
    then
      # Additionally run a script to monitor inactivity      
      #pkill -P $$ tail
      #id=$(echo "$container_name" | cut -d"-" -f3)
      #monitor_pid=$(cat "./monitoring_${id}")
      #kill $monitor_pid
      #rm "./monitoring_${id}"
      # date +%s > "$container_name"_timer.txt
      sleep 1m
      ./destroy_container.sh "$container_name" "$external_ip"
      break # No longer need to monitor for ssh connection, thus concluding the script
      else
        sleep 1
    fi
done


#sleep 10m
#./destroy_container.sh "$container_name" "$external_ip"
