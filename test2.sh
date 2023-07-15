#!/bin/bash

###############
# Please modify your cloud mqtt credential here
##############
m_i2c="3c"

################
# nothing needs to be changed below
##############
echo "Starting script sayIPbs "
private=`hostname -I | sed -E -e 's/[[:blank:]]+/_/g' `
i2c_cmd=`raspi-config nonint do_i2c 0`

mapfile -t data < <(i2cdetect -y 1)

for i in $(seq 1 ${#data[@]}); do
    line=(${data[$i]})
    echo ${line[@]:1} | grep -qw "$m_i2c"
    if [ $? -eq 0 ]; then
        test=` python3 /home/ubuntu/stats.py`
        exit 0
    fi
done
