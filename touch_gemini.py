#!/usr/bin/env python3
#
# Description: Mini Pupper touch panel test script.
#

import time
import RPi.GPIO as GPIO
import subprocess
import os
from playsound import playsound
import logging
import docker
import threading
import signal
import sys

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

gemini_process = None
gemini_thread = None

def gemini():
    global gemini_process
    playsound("/home/ubuntu/mini_pupper_bsp/Audio/start.mp3")
    try:
        cmd = ["python", "gemini_bot.py"]
        gemini_process = subprocess.Popen(cmd, cwd='/home/ubuntu/generative_ai', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = gemini_process.communicate()
        p_status = gemini_process.wait()
        if p_status != 0:
            logging.error(f"Command '{cmd}' failed with return code {p_status}")
            logging.error(stderr.decode())
    except Exception as e:
        # Log any exceptions
        logging.exception("An error occurred:")

def reset():
    global gemini_process, gemini_thread
    playsound("/home/ubuntu/mini_pupper_bsp/Audio/start.mp3")
    if gemini_process is not None:
        gemini_process.terminate()
        gemini_process.wait()
        gemini_process = None
    if gemini_thread is not None:
        gemini_thread.join()
        gemini_thread = None
    try:
        cmd = ["bash", "reset.sh"]
        p = subprocess.Popen(cmd, cwd='/home/ubuntu/startup', stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = p.communicate()
        p_status = p.wait()
        if p_status != 0:
            logging.error(f"Command '{cmd}' failed with return code {p_status}")
            logging.error(stderr.decode())
    except Exception as e:
        # Log any exceptions
        logging.exception("An error occurred:")

def dance():
    playsound("/home/ubuntu/mini_pupper_bsp/Audio/power_on.mp3")
    try:
        container_id = get_container_ids_by_name('pupper-robot')
        print(container_id[0])
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

# Function to handle SIGTERM signal
def signal_handler(sig, frame):
    print("Stopping the service...")
    GPIO.cleanup()  # Clean up GPIO
    sys.exit(0)

# Register signal handler for SIGTERM
signal.signal(signal.SIGTERM, signal_handler)

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

    if display_sting == ' Front':
        display_sting = ''
    elif display_sting == ' Front Right':
        print(display_sting)
        reset()
    elif display_sting == ' Front Left':
        if gemini_thread is None:
            gemini_thread = threading.Thread(target=gemini)
            gemini_thread.start()
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
