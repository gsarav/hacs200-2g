#!/bin/bash

if [[ $# -ne 2 ]];
then
  echo "usage: ./destroy_container.sh [container_name] [external_ip]"
  exit 1
fi

container_ip=$(sudo lxc-info -n "$1" | grep "IP" | xargs | cut -d" " -f2)
external_ip=$2
MITM_port=$(echo "$1" | cut -d"-" -f3)

container_name=$1

MITM_pid=$(sudo forever list 2>/dev/null | grep "$container_name" | xargs | cut -d" " -f19)
sudo forever stop "$MITM_pid"

# ==== DELETE MITM PREROUTING AND NAT RULES ====
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

# Delete MITM PREROUTING rule
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:"$MITM_port"

# ==== DELETE THE CONTAINER ====
sudo ip addr delete "$external_ip"/24 brd + dev eth3
sudo lxc-stop -n "$1"
sleep 3
sudo lxc-destroy -n "$1"
sleep 3

# ==== ADD THE NOW FREE IP ADDRESS BACK TO free_ip_addr.txt
#e cho "$external_ip" >> free_ip_addr.txt
# Call create_container.sh to create a new container

/home/student/create_container.sh "$external_ip"
