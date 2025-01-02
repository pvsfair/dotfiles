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
state=$(gsettings get org.gnome.desktop.notifications show-banners)

if [[ $state == 'true' ]]
then
  notify-send "Notifications: disabled";
  sleep 0.1;
  gsettings set org.gnome.desktop.notifications show-banners false
else
  gsettings set org.gnome.desktop.notifications show-banners true
  notify-send "Notifications: enabled"
fi
