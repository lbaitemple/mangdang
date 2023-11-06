#! /usr/bin/python3

import sys, os
from playsound import playsound

if __name__ == '__main__':
  os.system("amixer -c 0 sset 'Headphone' 100%")
  if (len(sys.argv) >1):
    playsound(sys.argv[1])
  else:
    playsound('how.mp3')
