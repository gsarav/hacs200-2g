#!/bin/bash

if [[ $# -ne 3 ]]
then
  echo "usage: ~/monitor.sh [configuration no.] [container_name] [external_ip]"
  exit 1
fi

container_name=$2
external_ip=$3
MITM_port=$(echo "$2" | cut -d"-" -f3)

mitm_log_path=""
if [[ $1 -eq 1 ]]
then
  mitm_log_path="/home/student/mitm_logs/banner-session-logs/${container_name}.log"
elif [[ $1 -eq 2 ]]
then
  mitm_log_path="/home/student/mitm_logs/banner-nosession-logs/${container_name}.log"
elif [[ $1 -eq 3 ]]
then
  mitm_log_path="/home/student/mitm_logs/nobanner-session-logs/${container_name}.log"
elif [[ $1 -eq 4 ]]
then
  mitm_log_path="/home/student/mitm_logs/nobanner-nosession-logs/${container_name}.log"
fi

#original sudo tail -F /var/lib/lxc/"$container_name"/rootfs/var/log/auth.log

# count=0

# valid_line=1

tail -F "$mitm_log_path" | while read -r line
do
  if echo "$line" | grep -q "Attacker connected";
  then

    echo "$line" | awk '{print $1, $2}' | xargs -I {} date -d "{}" +%s > /home/student/"$container_name"_start_time.txt
    sudo iptables --insert INPUT -d 10.0.3.1 -p tcp --dport "$MITM_port" --jump DROP
    attacker_ip=$(echo $line | cut -d" " -f8)
     # echo "Attacker IP= $attacker_ip"

    sudo iptables --insert INPUT -s "$attacker_ip" -d 10.0.3.1 -p tcp --dport "$MITM_port" --jump ACCEPT
    echo "$attacker_ip" > /home/student/"$container_name"_attacker_ip.txt
    date +%s > /home/student/"$container_name"_last_active.txt
    echo FIRST CONNECTION: $(cat /home/student/"$container_name"_last_active.txt)

    # valid_line=0
    break
  fi
done

start_time=$(cat /home/student/"$container_name"_start_time.txt)
attacker_ip=$(cat /home/student/"$container_name"_attacker_ip.txt)
# valid_line=0
current_time=0

# echo "START TIME: $start_time"

while [[ -f /home/student/"$container_name"_last_active.txt ]]
do
  # echo "CURRENT TIME: $current_time"
  timeout --foreground 1 tail -n 0 -F "$mitm_log_path" | while read -r line
  do
    date +%s > /home/student/"$container_name"_last_active.txt # Rewrite time of the last command
    if echo "$line" | grep -q "Attacker closed connection";
      then
        # echo "RECYCLING SINCE ATTACKER ENDED SESSION"
        rm /home/student/"$container_name"_last_active.txt
        break
    fi
  done

  current_time=$(date +%s)
  # echo "CURRENT TIME = $current_time"
  if [[ -f /home/student/"$container_name"_last_active.txt ]]
  then
    last_active=$(cat /home/student/"$container_name"_last_active.txt)
    if [[ $(($current_time - $last_active)) -ge 120 ]]
      then
      # valid_line=1
      echo "RECYCLING SINCE TIME IDLE EXCEEDED 60 SECONDS"
      rm /home/student/"$container_name"_last_active.txt
      break
    fi
  fi

  if [[ $(($start_time + 300)) -le $current_time ]]
  then
      echo "RECYCLING SINCE TIME EXCEEDED 2 MIN"
      rm /home/student/"$container_name"_last_active.txt
      break
  fi

done

sudo iptables --delete INPUT -d 10.0.3.1 -p tcp --dport "$MITM_port" --jump DROP
sudo iptables --delete INPUT -s "$attacker_ip" -d 10.0.3.1 -p tcp --dport "$MITM_port" --jump ACCEPT

rm /home/student/"$container_name"_start_time.txt
rm /home/student/"$container_name"_attacker_ip.txt
# rm "$container_name"_last_active.txt
/home/student/destroy_container.sh "$container_name" "$external_ip" 
