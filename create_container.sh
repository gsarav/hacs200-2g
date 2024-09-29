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
if [[ ! -s "free_ip_addr.txt" ]]
then
  echo "usage: 'free_ip_addr.txt' is empty-- please add valid IP addresses to file"
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
    container_name="banner-session" # banner with session files

  elif [[ "$random_number" -eq 2 ]]
  then
    container_name="banner-nosession" # banner with no session files

  elif [[ "$random_number" -eq 3 ]]
  then
    container_name="nobanner-session" # no banner with session files

  elif [[ "$random_number" -eq 4 ]]
  then
    container_name="nobanner-nosession" # empty container

fi

# Generating a random ID number for the container name
  container_name+=$(shuf -i 1-100000 -n 1)


# Creating the LXC container with $container_type
   sudo lxc-create -n "$container_name" -t download -- -d ubuntu -r focal -a amd64
# Wait 15 seconds for the container to start
  sleep 15

  sudo lxc-start -n "$container_name" # Start the container
  sleep 2 # Wait two seconds to start the container

  container_ip=$(sudo lxc-info -n "$container_name" | grep "IP" | xargs | cut -d" " -f2) # Getting new container's IP address
  external_ip=$($ip_addr) # External IP address that will route to the new container

# ========= CONFIGURE THE HONEYPOT =======
# Example: ./populate.sh "$container_name"
# 1. Copy files from VM to container depending on container type
# 2. Poison commands >> wget, curl, exit, logout 
# 3. Install up ssh on container
#
#
# 
# ==== SETTING UP NAT RULES ====
  sudo ip addr add "$external_ip"/16 brd + dev eth1
  sudo ip link set dev eth1 up
  sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --protocol tcp --dport 22 --jump DNAT --to-destination "$container_ip"
  sudo iptables --table nat --insert POSTROUTING --source "$container_ip" --destination 0.0.0.0/0 --jump SNAT --to-source "$external_ip"

# ==== SETTING UP MITM ====
# Generate a random port to open the MITM server
# Check if the port is in use, if it is, generate a new port
#  sudo sysctl -w net.ipv4.conf.all.route_localnet=1
#  MITM_port=$(shuf -i 1024-65535 -n 1) <---- MUST CHECK IF PORT IS ALREADY IN USE
#
#  sudo iptables --table nat --insert PREROUTING --source 0.0.0.0/0 --destination "$external_ip" --protocol tcp --dport 22 --jump DNAT --to-destination 127.0.0.1:"$MITM_port"
#  sudo lxc-attach -n "$container_name" -- sudo apt-get install openssh-server -y
#  sudo npm install -g forever
#  sudo forever -l ~/mitm_logs/"$container_name".log start node mitm.js -n "$container_name" -i "$container_ip" -p "$MITM_port" --auto-access --auto-access-fixed 1 --debug

#
#
#
# ==== MONITORING TO CHECK FOR SSH CONNECTION  ====
  ./monitor.sh "$container_name" & # The script stops running once "break" runs in the script

#
# ==== REMOVE IP ADDRESS FROM  "free_ip_addr.txt"
  sed -i '/"$ip_addr"/d' "free_ip_addr.txt"

done # Ending for loop to create a container for each IP address

exit 0
