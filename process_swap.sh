#!/usr/bin/bash

sudo dd if=/dev/zero of=/swap1 bs=1M count=$1
sudo mkswap /swap1
sudo swapon /swap1
sed -i 's/\/var\/swapfile swap swap defaults 0 0/\/swap1 swap swap/g' $2