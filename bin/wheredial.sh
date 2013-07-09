#!/bin/ash

# Init the Arduino
#stty -F /dev/ttyACM0 cs8 9600 -ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke -noflsh -ixon -crtscts
#stty -F /dev/ttyACM0

# Get the users MAC address
wheredial_mac=$(ifconfig | grep -m 1 -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}') 

# Touch a log file
log_file="/tmp/wheredial_log"
touch "$log_file"
echo "[$(uptime | awk '{print $1}')] - 0. Loading the wheredial ($wheredial_mac)" >> "$log_file"

while true; do

	# Turn on the error lights
	echo 12345 > /dev/ttyACM0

	# DNS
	wheredial_dns_ping=$(ping mapme.at -c 1)
	wheredial_dns_status=$(echo "$wheredial_dns_ping" | grep 'received' | awk -F',' '{ print $2}' | awk '{ print $1}')
	if [ "$wheredial_dns_status" != "1" ]; then
		echo "[$(uptime | awk '{print $1}')] - 1. DNS Error" >> "$log_file"
		echo 0 > /dev/ttyACM0
		sleep 6
		echo 543210 > /dev/ttyACM0
		sleep 2
		continue
	else
		wheredial_dns_ip=$(echo "$wheredial_dns_ping" | sed -n 's/.* \([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p')
		echo "[$(uptime | awk '{print $1}')] - 1. DNS Success, IP: $wheredial_dns_ip" >> "$log_file" 
		echo 5 > /dev/ttyACM0
	fi

	# Get the page source 
	wheredial_page_source=$(wget -S -qO- "http://mapme.at/api/wheredial.csv?mac=$wheredial_mac" 2>&1)
	if [ -n "$wheredial_page_source" ]; then
		echo "[$(uptime | awk '{print $1}')] - 2. Connected to server" >> "$log_file" 
		echo 4 > /dev/ttyACM0
	else 
		echo "[$(uptime | awk '{print $1}')] - 2. Couldn't connect to server" >> "$log_file" 	
		echo 0 > /dev/ttyACM0                                                                                       
		sleep 6                                                                                                     
		echo 43210 > /dev/ttyACM0                                                                                    
		sleep 2
		continue
	fi


	# Status Code
	wheredial_status_code=$(echo "$wheredial_page_source"| grep "HTTP/" | awk '{print $2}')

	if [ $wheredial_status_code -ge 200 ] &&  [ $wheredial_status_code -le 300 ]; then 
		echo "[$(uptime | awk '{print $1}')] - 3. Valid status code: $wheredial_status_code" >> "$log_file"
 		echo 3 > /dev/ttyACM0
	else
		echo "[$(uptime | awk '{print $1}')] - 3. Invalid status code: $wheredial_status_code" >> "$log_file" 
		echo 0 > /dev/ttyACM0
		sleep 6
		echo 3210 > /dev/ttyACM0
		sleep 2
		continue
	fi

	# Get page contnet
	wheredial_page_content=$(echo "$wheredial_page_source" | tail -1)

	# How much should I rotate?
	wheredial_position=$(echo $wheredial_page_content | sed -e "s/\(.*\),\(.*\)$/\1/")
		
	# What is the hash for my last request?
	wheredial_hash=$(echo $wheredial_page_content | sed -e "s/\(.*\),\(.*\)$/\2/")

	# Check we have the page content
	if [ -n $wheredial_position ] && [ -n $wheredial_hash ]; then
		echo "[$(uptime | awk '{print $1}')] - 4. Have page content" >> "$log_file" 
		if [ "$wheredial_hash" == "$wheredial_last_hash" ]; then
			echo "[$(uptime | awk '{print $1}')] - 5. Same hash, no action. ($wheredial_position,$wheredial_hash)" >> "$log_file" 
		else
			echo "[$(uptime | awk '{print $1}')] - 5. Differing/New hash, moving the dial $wheredial_position. Hash: $wheredial_hash" >> "$log_file"                                                        
			# Send move command to the dial                                                                    
			echo "t$wheredial_position" > /dev/ttyACM0                                                         
			# Need to think about this more ...                                                                
			awk  "BEGIN { rounded = sprintf(\"%.0f\", $wheredial_position*0.07); print rounded }" | xargs sleep
			echo "[$(uptime | awk '{print $1}')] - 6. Finished turning" >> "$log_file"       
		fi
		wheredial_last_hash="$wheredial_hash"
		echo 21 > /dev/ttyACM0 
	else
		echo "[$(uptime | awk '{print $1}')] - 4. Don't have page content" >> "$log_file" 	
		echo 0 > /dev/ttyACM0
		sleep 6
		echo 210
		sleep 2
		continue
	fi
	# Sleep for a moment. Hmm 60 times an hour, 1440 times a day :0
 	sleep 60
	
	echo "=============================================" >> "$log_file" 
done

exit 0
while true; do
	echo "1"
	wheredial_page_content=$(wget -qO- "http://live.mapme.at/wheredial.csv?mac=$wheredial_mac&position=$wheredial_position&placeHash=$wheredial_last_hash")
	wheredial_loop_position=$(echo $wheredial_page_content | sed -e "s/\(.*\),\(.*\)$/\1/")
	wheredial_last_hash=$(echo $wheredial_page_content | sed -e "s/\(.*\),\(.*\)$/\2/")
	
	echo "t$wheredial_loop_position" > /dev/ttyACM0
	
	echo "Update the dial!"
done
