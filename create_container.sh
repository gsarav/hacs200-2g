#!/bin/bash

# Steps for Creating a Container
# 1. Creating container (or in the future restoring a snapshot) and configuring it
#   a. Creating honey for type of configuration
#   b. Installing open-ssh on the container

# 2. Creating NAT
# 3. Setting up firewall
# 6. Removing NAT rules
# 7. Stopping and destroying container

# Checking that there are IP addresses to create containers for
if [[ ! -s "./free_ip_addr.txt" ]]
then
  echo "usage: './free_ip_addr.txt' is empty-- please add valid IP addresses to file"
  exit 1
fi

# Checking how many IP addresses are free- for each IP address that is free, we will create a new container.
readarray -t free_ip_addrs < free_ip_addr.txt

for ip_addr in "${free_ip_addrs[@]}"; # Going through each free IP address in our file
do

# ==== GENERATING RANDOM CONTAINERS ====
# Generating pseudo random number
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
  id=$(( $(tail -1 "id.txt") + 1 ))
  echo "$id" >> "id.txt"
  container_name="${container_name}${id}"
  echo "Container Name: $container_name"

# Creating the LXC container with container_type
  sudo lxc-create -n "$container_name" -t download -- -d ubuntu -r focal -a amd64
# Wait 15 seconds for the container to start
  sleep 25

  sudo lxc-start -n "$container_name" # Start the container
  sleep 5 # Wait two seconds to start the container

  container_ip=$(sudo lxc-info -i -H $container_name)
  external_ip="$ip_addr" # External IP address that will route to the new container
  echo "Container IP = $container_ip"
  echo "External IP = $external_ip"

# ========= CONFIGURE THE HONEYPOT =======
# Example: ./populate.sh "$container_name"
# 1. Copy files from VM to container depending on container type
# 2. Poison commands >> wget, curl, exit, logout
# 3. Install open ssh on container
#
  sudo lxc-attach -n "$container_name" -- bash -c "sudo apt-get update && sudo apt-get install openssh-server -y"
  sudo lxc-attach -n "$container_name" -- bash -c "sudo apt-get install -y curl"
  sudo lxc-attach -n "$container_name" -- bash -c "curl -fsSl https://ollama.com/install.sh | sh"
  sudo lxc-attach -n "$container_name" -- bash -c "ollama pull qwen:0.5b-chat-v1.5-q2_K"
  sudo lxc-attach -n "$container_name" -- bash -c "sudo systemctl stop ollama.service"


  if [[ "$random_number" -eq 1 ]]
  then
    ./NEWCONFIGMANAGER 1 $container_name
  elif [[ "$random_number" -eq 2 ]]
  then
    ./NEWCONFIGMANAGER 2 $container_name
  elif [[ "$random_number" -eq 3 ]]
  then
     ./NEWCONFIGMANAGER 3 $container_name
   elif [[ "$random_number" -eq 4 ]]
   then
     ./NEWCONFIGMANAGER 4 $container_name
  fi

  echo "NEWCONFIGMANAGER run"

  #sudo lxc-attach -n "$container_name" -- bash -c "sudo apt-get update && sudo apt-get install openssh-server -y"

# ==== SETTING UP NAT RULES ====
  sudo ip addr add "$external_ip"/24 brd + dev eth3
  # sudo ip link set dev eth3 up
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

  # touch ~/mitm_logs/"$log_path"/"$container_name".log
  sudo forever -l ~/mitm_logs/"$log_path"/"$container_name".log start -a /home/student/MITM/mitm.js -n "$container_name" -i "$container_ip" -p "$MITM_port" --mitm-ip 10.0.3.1 --auto-access --auto-access-fixed 1 --debug

#
#
#
# ==== MONITORING TO CHECK FOR SSH CONNECTION  ====
   ./monitor.sh "$container_name" "$external_ip" &
   monitor_pid=$!
   echo "$monitor_pid" > "./monitoring_${id}"

#
# ==== REMOVE IP ADDRESS FROM  "free_ip_addr.txt"
  sed -i "/$ip_addr/d" "./free_ip_addr.txt"

done # Ending for loop to create a container for each IP address

exit 0
