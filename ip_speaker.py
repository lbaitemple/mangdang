#!/usr/bin/env python
# coding: utf-8

# In[1]:





# In[5]:

from gtts import gTTS
import os
import netifaces as ni

def getIP():
    if ni.AF_INET in ni.ifaddresses('wlan0').keys():
        ip = ni.ifaddresses('wlan0')[ni.AF_INET][0]['addr']
    elif ni.AF_INET in ni.ifaddresses('eth0').keys():
        ip = ni.ifaddresses('eth0')[ni.AF_INET][0]['addr']
    else:
        ip = 'no IPv4 address found'
    
    text = f"IP address is: {ip}"
    tts = gTTS(text=text, lang='en')
    
    # Save to file
    tts.save("output.mp3")
    os.system("amixer -c 0 sset 'Headphone' 100%")
    # Play the audio (make sure mpg321 is installed)
    os.system("mpg321 output.mp3")


import RPi.GPIO as GPIO
import time
# There are 4 areas for touch actions
# Each GPIO to each touch area
touchPin_Front = 6
touchPin_Left  = 3
touchPin_Right = 16
touchPin_Back  = 2

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
        getIP()
    else:
        print(display_sting)
    time.sleep(0.5)

