#!/bin/ash

# Collect Wireless Network Settings
read -p "Wi-Fi SSID: " wifi_ssid
read -p "Wi-Fi Encryption (none, psk, psk2): " wifi_encryption
read -p "Wi-Fi Key: " -s wifi_key
echo

# Configure network timeouts
sed -i '/net\.ipv4\.tcp_keepalive_time=[[:digit:]]*/d' /etc/sysctl.conf 
cat << 'EOF' >> /etc/sysctl.conf

# Keep Alive Mod
net.ipv4.tcp_keepalive_intvl=10
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_time=10
EOF

# Mac addresses
wirelessMac=CC$(ifconfig | grep -m 1 -o -E ':([[:xdigit:]]{1,2}:){4}[[:xdigit:]]{1,2}')
wireMac=$(ifconfig | grep -m 1 -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')

# Configure the Network
uci set network.wwan=interface
uci set network.wwan.proto=dhcp

uci set network.wan=interface
uci set network.wan.proto=dhcp
uci set network.wan.ifname=eth0
uci set network.wan.macaddr="$wireMac"
uci delete network.lan
uci commit network

# Configure the Wireless
uci set wireless.@wifi-device[-1].disabled=0
uci set wireless.@wifi-device[-1].macaddr="$wirelessMac"
uci set wireless.@wifi-iface[-1].mode=sta
uci set wireless.@wifi-iface[-1].network=wwan
uci set wireless.@wifi-iface[-1].ssid=$wifi_ssid
uci set wireless.@wifi-iface[-1].encryption=$wifi_encryption
uci set wireless.@wifi-iface[-1].key=$wifi_key
uci commit wireless

# Configure the firewall
i=0
while true; do
	if [ $(uci get firewall.@zone[$i].name) == "wan" ]; then
		uci delete firewall.@zone[$i].network
		uci set firewall.@zone[$i].network='wan wwan'
		
		uci add firewall rule
		uci set firewall.@rule[-1].src=wan
		uci set firewall.@rule[-1].target=ACCEPT
		uci set firewall.@rule[-1].proto=tcp
		uci set firewall.@rule[-1].dest_port=22

		uci commit firewall
		break
	fi

	let i++
done

# Reload Config
/etc/init.d/network reload
/etc/init.d/firewall reload
wifi

# Install much needed package
sleep 10
opkg update
opkg install iwinfo

echo "Done."
