#!/bin/ash

# Get the users MAC address
wheredial_mac=$(ifconfig | grep -m 1 -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}') 

# Log file
log_file="/tmp/wheredial_log"
log() {                                                                     
	echo "[$(uptime | awk '{print $1}')] - $1. $2" >> "$log_file"               
}
log 0 "Loading the wheredial ($wheredial_mac)"

# Downloading Config
wheredial_config=$(/root/keepalivehttpc "http://mapme.at/api/wheredial.cs?config=yes&mac=$wheredial_mac" | tail -1)
wheredial_url=$(echo "$wheredial_config" | awk -F, '{print $1":"$2$3}')
wheredial_domain=$(echo "$wheredial_config" | awk -F, '{print $1}') 
wheredial_sleep=$(echo "$wheredial_config" | awk -F, '{print $4}')

while true; do

	# Turn on the error lights
	echo 12345 > /dev/ttyACM0

	# DNS
	wheredial_dns_ping=$(ping "$wheredial_domain" -c 1)
	wheredial_dns_status=$(echo "$wheredial_dns_ping" | sed -n 's/.* \([[:digit:]]\) packets received.*/\1/p') 
	if [ "$wheredial_dns_status" != "1" ]; then
		log 1 "DNS Error"
		echo 0 > /dev/ttyACM0
		sleep 6
		echo 543210 > /dev/ttyACM0
		sleep 2
		continue
	else
		wheredial_dns_ip=$(echo "$wheredial_dns_ping" | sed -n 's/.* \([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p')
		log 1 "DNS Success, IP: $wheredial_dns_ip" 
		echo 5 > /dev/ttyACM0
		sleep 1
	fi

	# Get the page source 
	wheredial_page_source=$(/root/keepalivehttpc "http://$wheredial_url?&position=$wheredial_position&placeHash=$wheredial_hash" )
	if [ -n "$wheredial_page_source" ]; then
		log 2 "Connected to server" 
		echo 4 > /dev/ttyACM0
		sleep 1
	else 
		log 2 "Couldn't connect to server" 
		echo 0 > /dev/ttyACM0 
		sleep 6
		43210 > /dev/ttyACM
		sleep 2
		continue
	fi

	# Status Code
	wheredial_status_code=$(echo "$wheredial_page_source"| grep "HTTP/1.1" | awk '{print $2}')

	if [ $wheredial_status_code -ge 200 ] &&  [ $wheredial_status_code -le 300 ]; then
		log 3 "Valid status code: $wheredial_status_code"
 		echo 3 > /dev/ttyACM0
		sleep 1
	else
		log 3 "Invalid status code: $wheredial_status_code"
		echo 0 > /dev/ttyACM0
		sleep 6
		echo 3210 > /dev/ttyACM0
		sleep 2
		continue
	fi

	# Get page contnet
	wheredial_page_content=$(echo "$wheredial_page_source" | tail -1)

	# How much should I rotate?
	wheredial_position=$(echo $wheredial_page_content | sed -n 's/^\([0-9]\{1,3\}\),\([[:alnum:]]\{40\}\)\(,[[:alnum:]]*\)*$/\1/p')

	# What is the hash for my last request?
	wheredial_hash=$(echo $wheredial_page_content | sed -n 's/^\([0-9]\{1,3\}\),\([[:alnum:]]\{40\}\)\(,[[:alnum:]]*\)*$/\2/p')

	# Check we have the page content
	if [ -n $wheredial_position ] && [ -n $wheredial_hash ]; then
		log 4 "Have page content"
		if [ "$wheredial_hash" == "$wheredial_last_hash" ]; then
			log 5 "Same hash, no action. ($wheredial_position,$wheredial_hash)"
		else
			log 5 "Differing/New hash, moving the dial $wheredial_position, hash: $wheredial_hash"
			# Send move command to the dial
			echo "t$wheredial_position" > /dev/ttyACM0
			
			# Wait for dial to turn
			diff=$(($wheredial_last_postion-$wheredial_position))
			if [ $diff -eq 0 ]; then diff=360; fi
			awk  "BEGIN { rounded = sprintf(\"%.0f\", $diff*0.0711); rounded=(rounded<0)?-rounded:rounded; print rounded }" | xargs sleep
			
			log 6 "Finished turning"
		fi
		wheredial_last_hash="$wheredial_hash"
		wheredial_last_position="$wheredial_position"
		echo 21 > /dev/ttyACM0 
	else
		echo "[$(uptime | awk '{print $1}')] - 4. Don't have page content" >> "$log_file" 	
		echo 0 > /dev/ttyACM0
		sleep 6
		echo 210
		sleep 2
		continue
	fi
 	
 	sleep $wheredial_sleep
	
	echo "=============================================" >> "$log_file" 
done

exit 0
