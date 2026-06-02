#!/bin/bash

# Author: Stanko Metodiev
# Author Email: stanko@metodiew.com
# Author URL: https://metodiew.com
# Description:  This is a script enabling/disabling the OS notifiications
# How to use:   Clone the repository or copy the file. Place it somewhere in the file system.
#               chmod +x ubuntu-notification-shortcut
#               Open the Settings > Keyboard > Keyboard Shortcodes > Custom Shortoces
#               Set the name, place the path to file, e.g. /home/<user>/Software/ubuntu-notification-shortcut and select the keyboard combination

# Get the current state of the notificiation mode
state=$(dunstctl is-paused)

if [[ $state == 'false' ]]
then
  notify-send "Notifications: disabled";
  sleep 0.3;
  dunstctl set-paused true
else
  notify-send "Notifications: enabled";
  dunstctl set-paused false
fi
