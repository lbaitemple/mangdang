#!/bin/bash


#wireless.txt content
#export USEROAM=1
#export ID=lbai@temple.edu
#export HASH=1ff3e3e2sfdssds53e5c8c429
#export AP=eduroam
#export WIFI_AP1=L5GLB_Ext
#export WIFI_AP1_PWD=fsfrweew
#export WIFI_AP2=YYDS
#export WIFI_AP2_PWD=rwerwe
#export CURRENT_WIF_AP=YYDS
#export CURREN_WIFI_PWD=chrisWifi
#export ADD_WIFI_AP="YYDTS"
#export ADD_WIFI_AP_PWD=erwrwecfs

FILE=/boot/firmware/wireless.txt
ACCESSFILE=/etc/netplan/50-cloud-init.yaml

#FILE=wireless.txt
#ACCESSFILE=50-cloud-init.yaml

if test -f "$FILE"; then
    cp $ACCESSFILE $ACCESSFILE.bak
    source $FILE

   # determine wifi access   WIFI_AP1  and WIFI_AP1_PWD and add the new WiFi
   if [ -n "$WIFI_AP1" ] && [ -n "$WIFI_AP1_PWD" ]; then
       cat  $ACCESSFILE | sed  -E "s/WIFI_AP1/$WIFI_AP1/" | \
       sed -E "s/password_ap1/$WIFI_AP1_PWD/"  > $ACCESSFILE.1
       cp $ACCESSFILE.1 $ACCESSFILE        
   fi
   
   # determine wifi access   WIFI_AP2  and WIFI_AP2_PWD and add the new WiFi
   if [ -n "$WIFI_AP2" ] && [ -n "$WIFI_AP2_PWD" ]; then
       cat  $ACCESSFILE | sed  -E "s/WIFI_AP2/$WIFI_AP2/" | \
       sed -E "s/password_ap2/$WIFI_AP2_PWD/"  > $ACCESSFILE.1
       cp $ACCESSFILE.1 $ACCESSFILE 
   fi

    # determine wifi access for eduroam
    if [ -n "$USEROAM" ]; then
       #echo ${AP}
       cat  $ACCESSFILE | sed  -E "s/hash:.+/hash:${HASH}/" | \
       sed -E "s/identity:.+/identity: ${ID}/" | sed  -E "s/(tusecurewireless|eduroam)/${AP}/" > $ACCESSFILE.1
    else
       #echo ${AP}
       cat  $ACCESSFILE | sed  -E "s/hash:.+/hash:${HASH}/" | \
       sed -E "s/identity:.+/identity: ${ID}/" | sed  -E "s/(tusecurewireless|eduroam)/${AP}/" > $ACCESSFILE.1
    fi

    # determine wifi access password change based  CURRENT_WIF_AP and CURREN_WIFI_PWD env varialbles
    if [ -n "$CURREN_WIFI_PWD" ] && [ -n "$CURRENT_WIF_AP" ]; then
        line_number=$(grep -n "$CURRENT_WIF_AP" "$ACCESSFILE" | cut -d: -f1)
        if [ -n "$line_number" ]; then
            # Increase line number by 1
            ((line_number++))
            #echo ${line_number}
            # Replace text at the specified line
            cat  $ACCESSFILE | sed -E "${line_number}s/password:.+/password: \"${CURREN_WIFI_PWD}\"/" > $ACCESSFILE.1
        fi
    fi


    # determine wifi access password change based  CURRENT_WIF_AP and CURREN_WIFI_PWD env varialbles
    if [ -n "$ADD_WIFI_AP" ] && [ -n "$ADD_WIFI_AP_PWD" ]; then
        line_number=$(grep -n "$ADD_WIFI_AP" "$ACCESSFILE" | cut -d: -f1)
        if [ -z "$line_number" ]; then
            # not find the exisiting wifi
            wifi_line_number=$(grep -n "access-points" "$ACCESSFILE" | cut -d: -f1)
            if [ -n "$wifi_line_number" ]; then
                ((wifi_line_number++))
                new_line1="    \"${ADD_WIFI_AP}\":"
                new_line2="        password: \"${ADD_WIFI_AP_PWD}\""
                cat  $ACCESSFILE | sed -E "${wifi_line_number}i\\
                    $new_line1\\
                    $new_line2" > $ACCESSFILE.1
            fi            
        fi

    fi
    
    cp $ACCESSFILE.1 $ACCESSFILE 
    rm $FILE
    rm $ACCESSFILE.1
    systemctl restart systemd-networkd
fi

