#! /usr/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install libcairo2-dev pkg-config python3-dev -y
pip install pycairo
sudo apt install libgirepository1.0-dev gstreamer1.0 python3-qtpy -y

pip install pygobject playsound
