#! /usr/bin/python3

import sys
from playsound import playsound

if __name__ == '__main__':
  if (len(sys.argv) >0):
    playsound(sys.argv[1])
  else:
    playsound('how.mp3')
