#!/bin/ash
# Variables -- Change these only
server="http://192.168.0.75:8888"
ssh_server="wheredial@192.168.0.75"
log_file="/tmp/wifi_log"

# Script Begins
log() {         
    echo "[$(uptime | awk '{print $1}')] - $1" >> "$log_file"
}

log "Wi-Fi configuration script begins"
mac=$(ifconfig | grep -m 1 -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
result="none"

while true; do
  if [ "$result" == "wifiscan" ]; then
    log "Doing wi-fi scan"
    scan_result=$(iwinfo wlan0 scan)
    scan_names=$(echo "$scan_result" | sed -n 's/[[:space:]]*ESSID: "\(.*\)"/\1/p' | sed ':a;N;$!ba;s/\n/%3B/g' | sed -f /root/urlencode.sed)
    scan_encryptions=$(echo "$scan_result" | grep Encryption | sed -f /root/encryption.sed | sed ':a;N;$!ba;s/\n/%3B/g' | sed -f /root/urlencode.sed)
    scan_signals=$(echo "$scan_result" | sed -n 's/[[:space:]]*Signal: -[[:digit:]]\{1,2\} dBm  Quality: \([[:digit:]]\{1,2\}\)\(.*\)/\1/p' | sed ':a;N;$!ba;s/\n/%3B/g' )
    result=$(/root/keepalivehttpc "$server/openwrt.csv?mac=$mac&action=wifiscan&scanNames=$scan_names&scanEncryptions=$scan_encryptions&scanSignals=$scan_signals")
    result=$(echo "$result" | tail -1)

  elif [ "$result" == "wificonnect" ]; then
    log "Setting the wi-fi"
    wifi_details=$(ssh -y -t -i /root/.ssh/id_rsa $ssh_server < /dev/ptmx | tail -1)
    password=$(echo $wifi_details | sed -e 's/^\([^,]*\),\([^,|]*\),\(none\|psk2\|wpa2+ccmp\|wep\|wpa2\|psk\).*$/\1/')
    wifiName=$(echo $wifi_details | sed -e 's/^\([^,]*\),\([^,|]*\),\(none\|psk2\|wpa2+ccmp\|wep\|wpa2\|psk\).*$/\2/')
    encryption=$(echo $wifi_details | sed -e 's/^\([^,]*\),\([^,|]*\),\(none\|psk2\|wpa2+ccmp\|wep\|wpa2\|psk\).*$/\3/')

    uci set wireless.@wifi-iface[-1].ssid=$wifiName
    uci set wireless.@wifi-iface[-1].key=$password
    uci set wireless.@wifi-iface[-1].encryption=$encryption
    uci commit wireless

    wifi down
    wifi up
    sleep 10

    connection=$(ifconfig wlan0 | grep 'inet addr')
    if [ -n "$connection" ]; then
      log "Connected to $wifiName"
      result=$(/root/keepalivehttpc "$server/openwrt.csv?mac=$mac&action=status&result=success")
      result=$(echo "$result" | tail -1)
    else
      log "Unable to connect to $wifiName"
      result=$(/root/keepalivehttpc "$server/openwrt.csv?mac=$mac&action=status&result=failed")
      result=$(echo "$result" | tail -1)
    fi
  else
    if [ "$result" == "none" ]; then
      sleep 1
    elif [ $? -eq 1 ]; then
      log "Server Error"
      sleep 20
    fi
    log "Generic Poll"
    log "Calling /root/keepalivehttpc \"$server/openwrt.csv?mac=$mac\" 2>&1"
    result=$(/root/keepalivehttpc "$server/openwrt.csv?mac=$mac" 2>&1)
    result=$(echo "$result" | tail -1)
    log $result
  fi

done
