s/[[:space:]]*Encryption: WEP Open\/Shared (NONE)/wep/g
s/[[:space:]]*Encryption: WPA 802.1X (TKIP, CCMP)/psk/g
s/[[:space:]]*Encryption: WPA PSK (TKIP)/psk/g
s/[[:space:]]*Encryption: WPA PSK (TKIP, CCMP)/psk/g
s/[[:space:]]*Encryption: WPA2 802.1X (CCMP)/wpa2+ccmp/g
s/[[:space:]]*Encryption: WPA2 PSK (CCMP)/psk2/g
s/[[:space:]]*Encryption: WPA2 PSK (TKIP)/psk2/g
s/[[:space:]]*Encryption: WPA2 PSK (TKIP, CCMP)/psk2/g
s/[[:space:]]*Encryption: mixed WPA\/WPA2 802.1X (TKIP, CCMP)/wpa2/g
s/[[:space:]]*Encryption: mixed WPA\/WPA2 PSK (CCMP)/psk2/g
s/[[:space:]]*Encryption: mixed WPA\/WPA2 PSK (TKIP)/psk2/g
s/[[:space:]]*Encryption: mixed WPA\/WPA2 PSK (TKIP, CCMP)/psk2/g
s/[[:space:]]*Encryption: none/none/g

