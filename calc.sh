#!/bin/bash

# Function to calculate CIDR block based on the number of IPs
calculate_cidr() {
    local ips=$1
    local mask=32
    while [ $mask -gt 0 ]; do
        local network_size=$((2 ** (32 - $mask)))
        if [ $ips -le $network_size ]; then
            echo "/$mask"
            break
        fi
        ((mask--))
    done
}

# Accept user input for the number of IPs
#read -p "Enter the number of IPs: " num_ips
num_ips=8

# Multiply the user input by 2
new_num_ips=$((num_ips * 2))

# Call the function to calculate CIDR block with the new value
calculate_cidr $new_num_ips > output.txt

