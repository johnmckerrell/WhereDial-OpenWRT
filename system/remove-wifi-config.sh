#!/bin/ash

# Remove Wi-Fi Key
uci delete wireless.@wifi-iface[-1].key
uci delete wireless.@wifi-iface[-1].ssid
uci delete wireless.@wifi-iface[-1].encryption
uci commit wireless

echo "Done."
