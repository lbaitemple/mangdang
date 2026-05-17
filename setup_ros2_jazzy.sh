#!/bin/bash

set -e

echo "======================================"
echo "ROS 2 Jazzy Installation Script"
echo "Ubuntu 24.04 on Raspberry Pi"
echo "======================================"

# Update system
sudo apt update
sudo apt full-upgrade -y

# Fix broken packages if needed
sudo apt --fix-broken install -y
sudo dpkg --configure -a

# Install required tools
sudo apt install -y \
    software-properties-common \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
    build-essential

# Enable universe repository
sudo add-apt-repository universe -y

# Add ROS 2 GPG key
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
    -o /usr/share/keyrings/ros-archive-keyring.gpg

# Add ROS 2 repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | \
sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# Update package lists
sudo apt update

# Upgrade again to synchronize package versions
sudo apt full-upgrade -y

# Install ROS 2 Jazzy ros-base
sudo apt install -y ros-jazzy-ros-base

# Install development tools
sudo apt install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    git

# Initialize rosdep
sudo rosdep init || true
rosdep update

# Source ROS automatically
if ! grep -q "source /opt/ros/jazzy/setup.bash" ~/.bashrc; then
    echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc
fi

# Source for current shell
source /opt/ros/jazzy/setup.bash

echo "======================================"
echo "ROS 2 Jazzy installation completed!"
echo "======================================"

echo "Test with:"
echo "source /opt/ros/jazzy/setup.bash"
echo "ros2 topic list"

