#!/usr/bin/env python3
#
# Copyright 2023 MangDang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Description: Mini Pupper touch pannel test script.
#
import time
import RPi.GPIO as GPIO
import subprocess, os
from playsound import playsound
import logging
import docker

def get_container_ids_by_name(container_name_pattern):
    # Create a Docker client
    client = docker.from_env()

    try:
        container_ids = []

        # Iterate over all containers
        for container in client.containers.list():
            # Check if the container name matches the specified pattern
            if container_name_pattern in container.name:
                container_ids.append(container.id[:12])

        return container_ids
    except Exception as e:
        print(f"An error occurred: {e}")

logging.basicConfig(filename='/home/ubuntu/startup/error.log', level=logging.ERROR)

# There are 4 areas for touch actions
# Each GPIO to each touch area
touchPin_Front = 6
touchPin_Left  = 3
touchPin_Right = 16
touchPin_Back  = 2

def dance():
    playsound("/home/ubuntu/mini_pupper_bsp/Audio/power_on.mp3")
    cmd = "bash /home/ubuntu/rundocker.sh"
    try:
        container_id = get_container_ids_by_name('pupper-robot')
        print(container_id[0])
        #cmd = ["docker", "exec", container_id, "your_command_here"]
        cmd = ["docker", "exec", container_id[0], "/bin/bash", "-c", 'source /opt/ros/humble/setup.bash && ros2 topic pub --once /dance_config std_msgs/String "data: \'demo\'"']

        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        p_status = p.wait()

        if p_status != 0:
            logging.error(f"Command '{cmd}' failed with return code {p_status}")
            logging.error(stderr.decode())
    except Exception as e:
        # Log any exceptions
        logging.exception("An error occurred:")


def killdocker():

    try:

        container_id = get_container_ids_by_name('pupper-robot')
        print(container_id)
        cmd = ["docker", "rm",  "-f", container_id[0]]

        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        p_status = p.wait()

        if p_status != 0:
            logging.error(f"Command '{cmd}' failed with return code {p_status}")
            logging.error(stderr.decode())
    except Exception as e:
        # Log any exceptions
        logging.exception("An error occurred:")


# Use GPIO number but not PIN number
GPIO.setmode(GPIO.BCM)

# Set up GPIO numbers to input
GPIO.setup(touchPin_Front, GPIO.IN)
GPIO.setup(touchPin_Left,  GPIO.IN)
GPIO.setup(touchPin_Right, GPIO.IN)
GPIO.setup(touchPin_Back,  GPIO.IN)
os.system("amixer -c 0 sset 'Headphone' 100%")
# Detection Loop
while True:
    touchValue_Front = GPIO.input(touchPin_Front)
    touchValue_Back  = GPIO.input(touchPin_Back)
    touchValue_Left  = GPIO.input(touchPin_Left)
    touchValue_Right = GPIO.input(touchPin_Right)
    display_sting = ''
    if not touchValue_Front:
        display_sting += ' Front'
    if not touchValue_Back:
        display_sting += ' Back'        
    if not touchValue_Right:
        display_sting += ' Right'      
    if not touchValue_Left:
        display_sting += ' Left'

    if display_sting == '':
        display_sting = ''
    elif display_sting == ' Front':
        playsound("/home/ubuntu/startup/bark.mp3")
    elif display_sting == ' Back':
        dance()
    elif display_sting == ' Right':
        playsound("/home/ubuntu/startup/whining.mp3")
    elif display_sting == ' Left':
        playsound("/home/ubuntu/startup/growling.wav")
    elif display_sting == ' Right Left':
        playsound("/home/ubuntu/startup/bark.mp3")
        killdocker()
    else:
        print(display_sting)
    time.sleep(0.5)