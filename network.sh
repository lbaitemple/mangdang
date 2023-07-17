#!/usr/bin/env bash

WIFI_SSID=eduroam
WIFI_PSK=password_at_temple
WIFI_USER=lbai@temple.edu

if [! -v "$WIFI_USER" ]; then
   # null or unset the user because personal wifi does not user username
   sudo nmcli con modify workshop wifi-sec.key-mgmt wpa-psk 
   sudo nmcli con modify workshop wifi-sec.psk ${WIFI_PSK} 
else
   # wpa-enterprise wifi need set username
   sudo nmcli con modify workshop 802-1x.eap peap 802-1x.phase2-auth mschapv2 802-1x.identity ${WIFI_USER} 802-1x.password ${WIFI_PSK} wifi-sec.key-mgmt wpa-eap
fi

sudo nmcli con up workshop

python3 /home/ubuntu/minipupper_ros_bsp/mangdang/LCD/demo.py
