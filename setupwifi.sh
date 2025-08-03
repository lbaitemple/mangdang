#!/bin/bash

FILE=/boot/firmware/wireless.txt
ACCESSFILE=/etc/netplan/50-cloud-init.yaml


if test -f "$FILE"; then
    cp $ACCESSFILE $ACCESSFILE.bak
    source $FILE

    if [ -n "$WIFI_AP1" ] && [ -n "$WIFI_AP1_PWD" ] && [ -n "$WIFI_AP2" ] && [ -n "$WIFI_AP2_PWD" ]; then
        # Update lines 17-20 using sed -i (in-place edits)
        sed -i "17s/\"[^\"]*\"/\"$WIFI_AP1\"/" $ACCESSFILE > $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
        sed -i "18s/password:.*/password: $WIFI_AP1_PWD/" $ACCESSFILE > $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
        sed -i "19s/\"[^\"]*\"/\"$WIFI_AP2\"/" $ACCESSFILE> $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
        sed -i "20s/password:.*/password: $WIFI_AP2_PWD/" $ACCESSFILE> $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
    fi

    # Handle USEROAM/other cases
    if [ -n "$USEROAM" ]; then
        sed -i "s/hash:.*/hash:${HASH}/; s/identity:.*/identity: ${ID}/; s/\(tusecurewireless\|eduroam\)/${AP}/" $ACCESSFILE> $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
    else
        sed -i "s/hash:.*/hash:${HASH}/; s/identity:.*/identity: ${ID}/; s/\(tusecurewireless\|eduroam\)/${AP}/" $ACCESSFILE> $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
    fi

    # Only handle regulatory-domain if COUNTRY_CODE exists in wireless.txt
    if [ -n "$COUNTRY_CODE" ]; then
        if grep -q "regulatory-domain:" $ACCESSFILE; then
            # If line exists, update it with proper alignment
            sed -i "s/regulatory-domain:.*/regulatory-domain: \"${COUNTRY_CODE}\"/" $ACCESSFILE> $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
        else
            # If line doesn't exist, add it with proper alignment (assuming wlan0 is indented 8 spaces)
            sed -i "/wlan0:/a \                regulatory-domain: \"${COUNTRY_CODE}\"" $ACCESSFILE> $ACCESSFILE.1
        cp $ACCESSFILE.1 $ACCESSFILE 
        fi
    fi

    rm $FILE
    systemctl restart systemd-networkd
fi
