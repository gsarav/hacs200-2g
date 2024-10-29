#!/bin/bash
modprobe br_netfilter
sysctl -p /etc/sysctl.conf
/bin/bash /home/student/firewall_rules.sh
#echo "firewall" > /home/student/test1
sudo ip link set dev eth3 up
# rm /home/student/free_ip_addr.txt
# echo "128.8.238.129" > /home/student/free_ip_addr.txt
# echo "128.8.238.90" >> /home/student/free_ip_addr.txt
# echo "128.8.238.179" >> /home/student/free_ip_addr.txt
/home/student/create_container.sh 128.8.238.129
/home/student/create_container.sh 128.8.238.90

# sudo /home/student/create_container.sh
