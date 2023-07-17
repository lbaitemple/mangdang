#!/usr/bin/env bash

#WIFI_USER=lbai@temple.edu # comment it out if you are using non wpa-enterprise network
WIFI_SSID=LSSID
WIFI_PSK=password123

sudo nmcli con delete workshop
sudo nmcli c add type wifi con-name workshop ifname wlan0 ssid ${WIFI_SSID}
if [ ! -v "$WIFI_USER" ]; then
   # null or unset the user because personal wifi does not user username
   sudo nmcli con modify workshop wifi-sec.key-mgmt wpa-psk
   sudo nmcli con modify workshop wifi-sec.psk ${WIFI_PSK} 
else
   # wpa-enterprise wifi need set username
   sudo nmcli con modify workshop 802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity ${WIFI_USER} 802-1x.password ${WIFI_PSK} wifi-sec.key-mgmt wpa-eap
fi

sudo nmcli con up workshop

python3 /home/ubuntu/minipupper_ros_bsp/mangdang/LCD/demo.py
