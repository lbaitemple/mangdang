#!/bin/bash

FILE=/boot/firmware/wireless.txt
ACCESSFILE=/etc/netplan/50-cloud-init.yaml

#FILE=wireless.txt
#ACCESSFILE=50-cloud-init.yaml

if test -f "$FILE"; then
    cp $ACCESSFILE $ACCESSFILE.bak
    source $FILE


    if [ -n "$WIFI_AP1" ] && [ -n "$WIFI_AP1_PWD" ] && [ -n "$WIFI_AP2" ] && [ -n "$WIFI_AP2_PWD" ]; then
    # Update line 17 (assuming line 17 contains WIFI_AP1 or a placeholder)
    sed -i.bak "17s/\"[^\"]*\"/\"$WIFI_AP1\"/" $ACCESSFILE
    
    # Update line 18 (assuming line 18 contains the password for WIFI_AP1 after "password: ")
    sed -i.bak '18s/password:.*/password: '"$WIFI_AP1_PWD"'/' $ACCESSFILE

    # Update line 19 for WIFI_AP2 (assuming line 19 contains WIFI_AP2 or a placeholder)
    sed -i.bak "19s/\"[^\"]*\"/\"$WIFI_AP2\"/" $ACCESSFILE
    
    # Update line 20 for WIFI_AP2_PWD (assuming line 20 contains the password for WIFI_AP2 after "password: ")
    sed -i.bak '20s/password:.*/password: '"$WIFI_AP2_PWD"'/' $ACCESSFILE
    fi

   #if [ -n "$WIFI_AP1" ] && [ -n "$WIFI_AP1_PWD" ]; then
   #    cat  $ACCESSFILE | sed  -E "s/WIFI_AP1/$WIFI_AP1/" | \
   #    sed -E "s/password_ap1/$WIFI_AP1_PWD/"  > $ACCESSFILE.1
   #    cp $ACCESSFILE.1 $ACCESSFILE        
   #fi

   #if [ -n "$WIFI_AP2" ] && [ -n "$WIFI_AP2_PWD" ]; then
   #    cat  $ACCESSFILE | sed  -E "s/WIFI_AP2/$WIFI_AP2/" | \
   #    sed -E "s/password_ap2/$WIFI_AP2_PWD/"  > $ACCESSFILE.1
   #    cp $ACCESSFILE.1 $ACCESSFILE 
   #fi

   if [ -n "$USEROAM" ]; then
       #echo ${AP}
       cat  $ACCESSFILE | sed  -E "s/hash:.+/hash:${HASH}/" | \
       sed -E "s/identity:.+/identity: ${ID}/" | sed  -E "s/(tusecurewireless|eduroam)/${AP}/" > $ACCESSFILE.1
   else
       #echo ${AP}
       cat  $ACCESSFILE | sed  -E "s/hash:.+/hash:${HASH}/" | \
       sed -E "s/identity:.+/identity: ${ID}/" | sed  -E "s/(tusecurewireless|eduroam)/${AP}/" > $ACCESSFILE.1
   fi
   cp $ACCESSFILE.1 $ACCESSFILE 
   rm $FILE
   rm $ACCESSFILE.1 $ACCESSFILE.bak
   systemctl restart systemd-networkd
fi

