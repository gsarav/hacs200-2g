#!/bin/bash
modprobe br_netfilter
sysctl -p /etc/sysctl.conf
/bin/bash /home/student/firewall_rules.sh
sudo ip link set dev eth3 up

/home/student/create_container.sh 128.8.238.129
/home/student/create_container.sh 128.8.238.90
/home/student/create_container.sh 128.8.238.141
/home/student/create_container.sh 128.8.238.159
/home/student/create_container.sh 128.8.238.137
