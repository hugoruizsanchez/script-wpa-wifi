#!/bin/bash
# Author: Hugo Ruiz
# WIFI CONNECTION CONTROL

# This script is responsible for connecting to a wifi network. It can be edited using parameters.
# -> to edit it using parameters: ./configure_network networkname password

# COLOR CODES

red="e[31m"
green="e[32m"
yellow="e[33m"
blue="e[34m"
bold="e[1m"
reset="e[0m"

# PROGRAM INTRODUCTION

sudo echo -e "${bold}*-------------------------------------*"
echo -e "| Wi-Fi Connection Script - WPA (wpa_supplicant)  |"
echo -e "| [ ] Script for network initialization and configuration |"
echo -e "| [ ] Hugo R.S -> github.com/hugoruizsanchez         |"
echo -e "*----------------------------------------------------*${reset}"
echo ""

while true; do

    # ACTIVATE NETWORK INTERFACE

    sudo ifconfig wlan0 up

    echo -e " ${bold} ${green}[ ]${reset} ${bold}wlan0 network interface activated.${reset}"

    # INITIAL IP VERIFICATION (Check if the user is already connected)

    ip_status=$(ip addr show dev wlan0 | grep "inet ")
    network_status=$(sudo curl -I www.google.com 2>&1 | grep "HTTP")

    if [ -n "$network_status" ] && [ -z "$1" ] && [ -z "$2" ]; then

        echo -e " ${bold} ${green}[ ]${reset} ${bold}The device is already connected to the internet. Current network interface status:${reset}"
        echo ""
        sudo iwconfig wlan0

    else

        if [ -n "$ip_status" ] && [ -n "$1" ] && [ -n "$2" ]; then

            echo -e " ${bold} ${yellow}[!]${reset} ${bold}You are connected to a network, but you have entered new parameters.${reset}"
            echo -e " ${bold} ${yellow}[!]${reset} ${bold}Disconnected from the internet.${reset}"

            sudo wpa_cli -i wlan0 disconnect >/dev/null
            sudo killall wpa_supplicant

            echo -e " ${bold} ${green}[!]${reset} ${bold}Disconnected from the network.${reset}"

        else

            echo -e " ${bold} ${yellow}[!]${reset} ${bold}You are not connected to any stable network. Current network interface status:${reset}"

        fi

        echo ""

        sudo iwconfig wlan0

        # SHOW AVAILABLE CONNECTIONS

        echo -e " ${bold} ${yellow}[!]${reset} ${bold}Before proceeding, check the status of available connections:${reset}"

        iwlist wlan0 scanning | grep -E "ESSID|Bit Rates|WPA"

        # PARAMETER DECLARATION

        network_name=$1
        password=$2

        # EXPORT FILE IF PARAMETERS ARE PROVIDED

        if [ -n "$1" ] && [ -n "$2" ]; then # -> If parameter 1 ($1) and parameter 2 ($2) exist...

            echo -e " ${bold} ${green}[ ]${reset} ${bold}You have entered parameters. Overwriting /$USER/.config/network_configuration.conf.${reset}"

            sudo wpa_passphrase $network_name $password >/home/$USER/.config/network_configuration.conf # -> Export configuration file to .config

            echo -e " ${bold} ${green}[ ]${reset} ${bold}Configuration saved in home/$USER/.config/network_configuration.conf.${reset}"

        else # -> ... if not...

            echo -e " ${bold} ${yellow}[!]${reset} ${bold}No parameters have been entered. This may be because it is a startup session.${reset}"

        fi

        # CHECK IF CONFIGURATION FILE EXISTS

        if [ ! -f "/home/$USER/.config/network_configuration.conf" ]; then # If the file does not exist (!f), then...

            echo -e " ${bold} ${red}[-]${reset} ${bold}Configuration file not found. To proceed, run the script again with the parameters networkname and password in bash.${reset}"

            exit 0

        fi

        # CONNECT TO THE NETWORK USING THE network_configuration.conf FILE

        echo -e " ${bold} ${green}[ ]${reset} ${bold}Configuration file found at /$USER/.config/network_configuration.conf.${reset}"

        echo -e " ${bold} ${green}[ ]${reset} ${bold}Connecting to the network using the network_configuration.conf file.${reset}"

        sudo wpa_supplicant -B -i wlan0 -c /home/$USER/.config/network_configuration.conf >/dev/null # Connect to the network using the file.

        echo -e " ${bold} ${green}[ ]${reset} ${bold}Network connected, but not yet connected. IP verification and assignment required.${reset}"

    fi

    # IP CONFIGURATION

    echo -e " ${bold} ${yellow}[!]${reset} ${bold}Configuring IP address.${reset}"

    sudo dhclient -v wlan0 >/dev/null 2>&1 # -> Assign IP to establish the connection

    # VERIFY IP

    ip_status=$(ip addr show dev wlan0 | grep "inet ")

    if [ -n "$ip_status" ]; then

        echo -e " ${bold} ${green}[ ]${reset} ${bold}IP address successfully assigned. The device is already connected to the internet. Current network interface status:${reset}"
        echo ""

        sudo iwconfig wlan0

        echo -e " ${bold} ${green}[ ]${reset} ${bold}And the IP address used for the connection is:${reset}"
        echo ""

        sudo ip addr show dev wlan0 | grep "inet "

        break

    else

        echo -e " ${bold} ${red}[-]${reset} ${bold}Network not connected, connection issues.${reset}"
        echo -e " ${bold} ${yellow}[!]${reset} ${bold}Do you want to retry? Y/N${reset}"
        read -p "     -> " input

        if [ "$input" != "Y" ]; then
            exit 0
        fi

    fi
done

echo -e " ${bold} ${yellow}[!]${reset} ${bold}Start constant connection verification process? Y/N${reset}"

read -p "     -> " input

if [ "$input" != "Y" ]; then
    exit 0
fi

while true; do

    network_status=$(sudo curl -I www.google.com 2>&1 | grep "HTTP")

    sleep 1

    if [ -z "$network_status" ]; then
        echo -e " ${bold} ${red}[-]${reset} ${bold}Connection dropped, attempting to reconnect.${reset}"
        echo -e " ${bold} ${yellow}[!]${reset} ${bold}Configuring IP address.${reset}"
        sudo dhclient -v wlan0 >/dev/null 2>&1 # -> Assign IP to establish the connection
    else
        echo -e " ${bold} ${green}[ ]${reset} ${bold}Connection established.${reset}"
        ping google.com -c 1 2>&1 | grep "bytes"
        echo ""
    fi

done

# END OF PROGRAM watch -n 5
