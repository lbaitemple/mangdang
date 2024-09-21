#
# Copyright 2024 MangDang (www.mangdang.net)
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
# Description: This script is designed to control a robot by sending various commands through UDP communication to simulate
# joystick inputs. It includes functions for different robot movements and an interactive command-line interface to issue these commands.
#

import logging
import os
import asyncio
import sys
import time
import threading
import copy

sys.path.append("..")
from api.UDPComms import Publisher


fake_joy = Publisher(8830, "127.0.0.1")
#fake_joy = Publisher(8830, "192.168.1.101")

_MSG = {"L1": False,
        "R1": False,
        "L2": -1.0,
        "R2": -1.0,
        "x": False,
        "square": False,
        "circle": False,
        "triangle": False,
        "lx": 0.0,
        "ly": 0.0,
        "rx": 0.0,
        "ry": 0.0,
        "dpadx": 0,
        "dpady": 0,
        "message_rate": 20
        }

MSG_L1_TRUE = {**_MSG, "L1": True}
MSG_L1_FALSE = {**_MSG, "L1": False}
MSG_R1 = {**_MSG, "R1": True}
MSG_X = {**_MSG, "x": True}
MSG_SQUARE = {**_MSG, "square": True}
MSG_CIRCLE = {**_MSG, "circle": True}
MSG_TRIANGLE = {**_MSG, "triangle": True}
MSG_RATE_10 = {**_MSG, "message_rate": 10}
UPDATE_INTERVAL = 0.1

def send_msgs(msgs):
    """
    Send a series of messages with a delay between each.

    Parameters:
    - msgs (list): A list of messages to be sent.
    """

    def send_updates():
        for msg in msgs:
            fake_joy.send(msg)
            time.sleep(UPDATE_INTERVAL)

    thread = threading.Thread(target=send_updates)
    thread.start()

# Active pupyy, fake "L1" button
def init_movement():
    """
    Activate the robot and initiate a movement by simulating the "L1" button press.
    """
    msg_raise = {**_MSG, "dpady": 1}
    send_msgs([MSG_L1_TRUE, MSG_L1_FALSE, msg_raise])

def trot():
    """
    Make the robot start trot.

    """
    msg_press = {**_MSG, "R1": True}
    msg_release = {**_MSG, "R1": False}
    msg = [msg_press, msg_release]
    send_msgs(msg)

def delay_trot(delay):
    time.sleep(delay)
    trot()

def trot_duration(duration=1):
    """
    Make the robot trot.

    Parameters:
    - duration (float): The duration of the movement.
    """
    trot()
    thread = threading.Thread(target=delay_trot, args=(duration,))
    thread.start()

def move_forward(duration=2):
    """
    Make the robot move forward.

    Parameters:
    - duration (float): The duration of the movement.
    """
    msg_trot_press = {**_MSG, "R1": True}
    msg_trot_release = {**_MSG, "R1": False}
    start_msg = {**_MSG, "ly": 1.0}
    stop_msg = {**_MSG, "ly": 0.0}
   
    return msg_trot_press, msg_trot_release, start_msg, stop_msg

def look_up(duration=2):
    """
    Make the robot look up.

    Parameters:
    - duration (float): The duration of the movement.
    """
    start_msg = {**_MSG, "ry": 1.0}
    stop_msg = {**_MSG, "ry": 0.0}
    msg_trot_press = {**_MSG, "R1": True}
    msg_trot_release = {**_MSG, "R1": False}
   
    return msg_trot_press, msg_trot_release, start_msg, stop_msg

def look_down(duration=2):
    """
    Make the robot look down.

    Parameters:
    - duration (float): The duration of the movement.
    """
    start_msg = {**_MSG, "ry": -1.0}
    stop_msg = {**_MSG, "ry": 0.0}
    msg_trot_press = {**_MSG, "R1": True}
    msg_trot_release = {**_MSG, "R1": False}
    
    return msg_trot_press, msg_trot_release, start_msg, stop_msg

def look_left(duration=2):
    """
    Make the robot look left.

    Parameters:
    - duration (float): The duration of the movement.
    """
    start_msg = {**_MSG, "rx": -1.0}
    stop_msg = {**_MSG, "rx": 0.0}
    msg_trot_press = {**_MSG, "R1": True}
    msg_trot_release = {**_MSG, "R1": False}

    return msg_trot_press, msg_trot_release, start_msg, stop_msg

def look_right(duration=2):
    """
    Make the robot look right.

    Parameters:
    - duration (float): The duration of the movement.
    """
    start_msg = {**_MSG, "rx": 1.0}
    stop_msg = {**_MSG, "rx": 0.0}
    msg_trot_press = {**_MSG, "R1": True}
    msg_trot_release = {**_MSG, "R1": False}

    return msg_trot_press, msg_trot_release, start_msg, stop_msg