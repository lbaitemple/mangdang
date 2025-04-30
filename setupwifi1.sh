#!/bin/bash

FILE=/boot/firmware/wireless.txt
ACCESSFILE=/etc/netplan/50-cloud-init.yaml

if test -f "$FILE"; then
    cp $ACCESSFILE $ACCESSFILE.bak
    source $FILE

    if [ -n "$WIFI_AP1" ] && [ -n "$WIFI_AP1_PWD" ] && [ -n "$WIFI_AP2" ] && [ -n "$WIFI_AP2_PWD" ]; then
        # Update lines 17-20 using sed -i (in-place edits)
        sed -i "17s/\"[^\"]*\"/\"$WIFI_AP1\"/" $ACCESSFILE
        sed -i "18s/password:.*/password: $WIFI_AP1_PWD/" $ACCESSFILE
        sed -i "19s/\"[^\"]*\"/\"$WIFI_AP2\"/" $ACCESSFILE
        sed -i "20s/password:.*/password: $WIFI_AP2_PWD/" $ACCESSFILE
    fi

    # Handle USEROAM/other cases
    if [ -n "$USEROAM" ]; then
        sed -i "s/hash:.*/hash:${HASH}/; s/identity:.*/identity: ${ID}/; s/\(tusecurewireless\|eduroam\)/${AP}/" $ACCESSFILE
    else
        sed -i "s/hash:.*/hash:${HASH}/; s/identity:.*/identity: ${ID}/; s/\(tusecurewireless\|eduroam\)/${AP}/" $ACCESSFILE
    fi

    rm $FILE
    systemctl restart systemd-networkd
fi
