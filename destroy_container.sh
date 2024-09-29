#!/bin/bash

# Steps for Destroying a Container
# 1. Removing NAT rules
# 2. Stopping and destroying the container
#

if [[ $# -ne 2 ]];
then
  echo "usage: ./destroy_container.sh [container_name] [external ip]"
  exit 1
fi

container_ip=$(sudo lxc-info -n "$1" | grep "IP" | xargs | cut -d" " -f2)
external_ip=$2

# ==== DELETE MITM PREROUTING AND NAT RULES ====
sudo iptables --table nat --delete PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --protocol tcp --dport 22 --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --delete POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"
# delete MITM PREROUTING rule
#
# ==== DELETE THE CONTAINER ====
sudo ip addr delete "$external_ip"/16 brd + dev eth1
sudo lxc-stop -n "$1"
sleep 3
sudo lxc-destroy -n "$1"
sleep 3

# ==== ADD THE NOW FREE IP ADDRESS BACK TO free_ip_addr.txt
echo "$external_ip" >> free_ip_addr.txt
# Call create_container.sh to create a new container

#./create_container.sh
