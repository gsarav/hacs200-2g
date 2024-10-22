#!/bin/bash

red=$(tput setaf 1)
yellow=$(tput setaf 3)
white=$(tput setaf 7)
green=$(tput setaf 2)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

echo -e "${red}$(figlet -f slant 'Welcome to')${reset}"
echo -e "${white}$(figlet -f slant "University of Maryland's")${reset}"
echo -e "${yellow}$(figlet -f slant 'Official Chatbot')${reset}"

echo -e "${white}==============================================================${reset}"
echo -e "${red}  ⚠️  You are now interacting with a chatbot ⚠️ ${reset}"
echo -e "${red}  This system is monitored for quality and security.${reset}"
echo -e "${red}  All interactions are recorded for further analysis.${reset}"
echo -e "${white}==============================================================${reset}"

echo -e "${white}*${reset} ${green}This chatbot is designed to assist you with queries related to academic services, general campus information, and more.${reset}"
echo -e "${white}*${reset} ${green}Feel free to ask questions, explore resources, or get personalized help from the comfort of your device.${reset}"
echo -e "${white}*${reset} ${green}For information on how to use a chatbot, refer to the HELP file.${reset}"
echo -e "${white}*${reset} ${green}Our chatbot is here to provide fast, 24/7 support.${reset}"
echo -e "${white}==============================================================${reset}"

echo -e "${red}ALERT: ${white}Chatbot active and ready to assist.${reset}"
echo -e "${red}ALERT: ${white}Use Chatbot by running the command 'ollama run qwen:0.5b-chat-v1.5-q2_K'${reset}"
