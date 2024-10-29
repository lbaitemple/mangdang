#!/usr/bin/env python

# the duration of every command
interval_time = 0.6 # seconds

# there are 10 commands you can choose:
# move_forward: the robot will move forward
# move_backward: the robot will move backward
# move_left: the robot will move to the left
# move_right: the robot will move to the right
# look_up: the robot will look up
# look_down: the robot will look down
# look_left: the robot will look left
# look_right: the robot will look right
# stop: the robot will stop the last command and return to the default standing posture
# stay: the robot will keep the last command
dance_commands = [
'music:robot0.mp3:0.0',
'move_forward:0.3:0.5',
'stop:0.0:0.5',
'look_down:0.3:0.5', 
'look_up:-0.3:0.5',

'move_backward:-0.3:0.5',
'stop:0.0:0.5',
'look_left:0.3:0.5',
'look_right:-0.3:0.5',

'move_left:0.3:0.5',
'stop:0.0:0.5',
'look_up-0.3:0.5',
'look_left:0.3:0.5',

'move_right:-0.3:0.5',
'stop:0.0:0.5',
'look_down:0.3:0.5', 
'look_right:-0.3:0.5',

'look_up-0.3:0.5',
'look_left:0.3:0.5',
'look_down:0.3:0.5', 
'look_right:-0.3:0.5',

'look_down:0.3:0.5', 
'look_left0:.3:0.5',
'look_up-0.3:0.5',
'look_right:-0.3:0.5',
'music:off:'
]
