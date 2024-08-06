#!/bin/bash
# code created from chatgpt

# Detect playback device
playback_device=$(aplay -l | grep -m 1 '^card' | awk '{print $2}' | sed 's/://')
playback_subdevice=$(aplay -l | grep -m 1 '^card' | awk '{print $6}')

# Detect capture device
capture_device=$(arecord -l | grep -m 1 '^card' | awk '{print $2}' | sed 's/://')
capture_subdevice=$(arecord -l | grep -m 1 '^card' | awk '{print $6}')

# Create asound.conf file
cat <<EOL > ~/.asoundrc
pcm.!default {
    type asym
    playback.pcm {
        type plug
        slave.pcm "hw:${playback_device},${playback_subdevice}"  # Playback device
    }
    capture.pcm {
        type plug
        slave.pcm "hw:${capture_device},${capture_subdevice}"    # Capture device
    }
}

ctl.!default {
    type hw
    card ${playback_device}  # Control device
}
EOL

echo "asound.conf file created at ~/.asoundrc"
