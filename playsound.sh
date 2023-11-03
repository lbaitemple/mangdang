#! /usr/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install libcairo2-dev pkg-config python3-dev -y
pip install pycairo
sudo apt install libgirepository1.0-dev python3-qtpy -y
sudo apt-get install gstreamer1.0 -y


pip install pygobject playsound

