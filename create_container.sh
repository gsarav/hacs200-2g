#!/bin/bash

if [[ $# -ne 1 ]]
then
  echo "usage: ./create_container.sh [ external_ip ]" 
  exit 1
fi

# sed -i '/^$/d' /home/student/free_ip_addr.txt # Remove empty lines in free_ip_addr.txt

# Checking how many IP addresses are free- for each IP address that is free, we will create a new container.

#echo Removing "$ip_addr" from free_ip_addr.txt
#echo Current free IPs: $(cat "/home/student/free_ip_addr.txt")

  # sed -i "/$ip_addr/d" "/home/student/free_ip_addr.txt"
# ==== GENERATING RANDOM CONTAINERS ====
# Generating pseudo random number
echo Creating a container for "$1"
random_number=$(shuf -i 1-4 -n 1)
container_name=""

if [[ "$random_number" -eq 1 ]]
then
  container_name="banner-session-" # banner with session files

elif [[ "$random_number" -eq 2 ]]
then
  container_name="banner-nosession-" # banner with no session files

elif [[ "$random_number" -eq 3 ]]
then
  container_name="nobanner-session-" # no banner with session files

elif [[ "$random_number" -eq 4 ]]
then
  container_name="nobanner-nosession-" # empty container

fi

# Generating an ID number for the container name based on the IP address
id=$(( $(tail -1 "/home/student/id.txt") + 1 ))
echo "$id" >> /home/student/id.txt
container_name="${container_name}${id}"
echo "Container Name: $container_name"

# Creating the LXC container with container_type
sudo lxc-create -n "$container_name" -t download -- -d ubuntu -r focal -a amd64
# Wait 15 seconds for the container to start
# sleep 25
sudo lxc-start -n "$container_name" # Start the container
while ! sudo lxc-info -n "$container_name" | grep -q "RUNNING"; do
  sleep 1
done
#sleep 5 # Wait two seconds to start the container
while true; do
  container_ip=$(sudo lxc-info -i -H $container_name 2>/dev/null)
  if [ -n "$container_ip" ]
  then
    break
  fi
  sleep 1
done

external_ip="$1" # External IP address that will route to the new container
echo "Container IP = $container_ip"
echo "External IP = $external_ip"


sudo lxc-attach -n "$container_name" -- bash -c "sudo apt-get update && sudo apt-get install openssh-server -y" 
sudo lxc-attach -n "$container_name" -- bash -c "sudo apt-get install -y curl"
# sudo lxc-attach -n "$container_name" -- bash -c "curl -fsSl https://ollama.com/install.sh | sh" 
# sudo lxc-attach -n "$container_name" -- bash -c "ollama pull qwen:0.5b-chat-v1.5-q2_K"

if [[ "$random_number" -eq 1 ]]
then
  /home/student/NEWCONFIGMANAGER 1 $container_name
elif [[ "$random_number" -eq 2 ]]
then
  /home/student/NEWCONFIGMANAGER 2 $container_name
elif [[ "$random_number" -eq 3 ]]
then
    /home/student/NEWCONFIGMANAGER 3 $container_name
  elif [[ "$random_number" -eq 4 ]]
  then
    /home/student/NEWCONFIGMANAGER 4 $container_name
fi

echo "NEWCONFIGMANAGER run"


# ==== SETTING UP NAT RULES ====
sudo ip addr add "$external_ip"/24 brd + dev eth3
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --jump DNAT --to-destination "$container_ip"
sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"
echo "NAT setup" 

# ==== SETTING UP MITM ====
MITM_port=$id # using port equal to the container id
sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --protocol tcp --dport 22 --jump DNAT --to-destination 10.0.3.1:"$MITM_port"
sudo sysctl -w net.ipv4.conf.all.route_localnet=1

echo "MITM setup"
# sudo npm install -g forever
log_path=""
if [[ "$random_number" -eq 1 ]]
then
  log_path="banner-session-logs"
elif [[ "$random_number" -eq 2 ]]
then
    log_path="banner-nosession-logs"
elif [[ "$random_number" -eq 3 ]]
then
    log_path="nobanner-session-logs"
  elif [[ "$random_number" -eq 4 ]]
  then
    log_path="nobanner-nosession-logs"
fi

sudo forever -l /home/student/mitm_logs/"$log_path"/"$container_name".log start -a /home/student/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$MITM_port" --mitm-ip 10.0.3.1 --auto-access --auto-access-fixed 1 --debug
# date > test.txt

#
#
#
# ==== MONITORING TO CHECK FOR SSH CONNECTION  ====
/home/student/monitor.sh "$random_number" "$container_name" "$external_ip" & 
#echo $!
#monitor_pid=$!
#echo "$monitor_pid" > "./monitoring_${id}"

exit 0

