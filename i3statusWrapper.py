#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# This script is a simple wrapper which prefixes each i3status line with custom
# information. It is a python reimplementation of:
# http://code.stapelberg.de/git/i3status/tree/contrib/wrapper.pl
#
# To use it, ensure your ~/.i3status.conf contains this line:
#     output_format = "i3bar"
# in the 'general' section.
# Then, in your ~/.i3/config, use:
#     status_command i3status | ~/i3status/contrib/wrapper.py
# In the 'bar' section.
#
# In its current version it will display the cpu frequency governor, but you
# are free to change it to display whatever you like, see the comment in the
# source code below.
#
# © 2012 Valentin Haenel <valentin.haenel@gmx.de>
#
# This program is free software. It comes without any warranty, to the extent
# permitted by applicable law. You can redistribute it and/or modify it under
# the terms of the Do What The Fuck You Want To Public License (WTFPL), Version
# 2, as published by Sam Hocevar. See http://sam.zoy.org/wtfpl/COPYING for more
# details.

import sys
import json
import subprocess
import requests
import datetime

def notification_status():
    status = subprocess.run("dunstctl is-paused", shell=True, capture_output=True).stdout.decode("utf-8").strip()
    return "🔕" if status == "true" else "🔔"

def get_headset_battery_status():
    devices = subprocess.run("upower -e", shell=True, capture_output=True).stdout.decode("utf-8").strip().split("\n")
    headset = [device for device in devices if "headset" in device]
    if len(headset) == 0:
        return {"full_text": "🎧🚫", "name": "headset"}

    headset = headset[0]
    battery = subprocess.run(f"upower -i {headset} | grep percentage | awk '{{print $2}}'", shell=True, capture_output=True).stdout.decode("utf-8").strip()
    battery_num = int(battery[:-1])
    icon = "🔋" if battery_num > 20 else "🪫"
    return {"full_text": "🎧" + icon + battery, "name": "headset"}

def get_temperature_status():
    secs = datetime.datetime.now().second
    if secs >= 5:
        return {"full_text": read_from_file(), "name": "temp"}
    try:
        # covilha
        r = requests.get("https://api.openweathermap.org/data/2.5/weather?lat=40.267148&lon=-7.5164369&appid=57210b8c5a36e6a88383e8ae9716f8d6&lang=pt_br&units=metric")
        # porto office
        # r = requests.get("https://api.openweathermap.org/data/2.5/weather?lat=41.1534365&lon=-8.6083718&appid=57210b8c5a36e6a88383e8ae9716f8d6&lang=pt_br&units=metric")
        if r.status_code != 200:
            return {"full_text": "🌡️FAIL", "name": "temp"}
        data = r.json()
        temp = data["main"]["temp"]
        feels_like = data["main"]["feels_like"]
        icon_name = data["weather"][0]["icon"][:2]
        text = data["weather"][0]["description"]
        icon = ""
        if icon_name == "01":
            icon = "☀️"
        elif icon_name == "02":
            icon = "⛅"
        elif icon_name == "03":
            icon = "☁️"
        elif icon_name == "04":
            icon = "☁️"
        elif icon_name == "09":
            icon = "🌧️"
        elif icon_name == "10":
            icon = "🌦️"
        elif icon_name == "11":
            icon = "🌩️"
        elif icon_name == "13":
            icon = "❄️"
        elif icon_name == "50":
            icon = "🌫️"
        t = f"{icon} {str(temp)}°C ({str(feels_like)}°C)"
        save_to_file(t)
        return {"full_text": f"{t}", "name": "temp"}
    except:
        return {"full_text": read_from_file(), "name": "temp"}
        # return "🌡️⟳"

def save_to_file(str):
    with open("/tmp/i3statusWrapperTemp.txt", "w") as f:
        f.write(str)

def read_from_file():
    try:
        with open("/tmp/i3statusWrapperTemp.txt", "r") as f:
            return f.read()
    except:
        return "🌡️⟳"

def music():
    try:
        music_name = subprocess.run("$HOME/spotify_control getName", shell=True, capture_output=True).stdout.decode("utf-8").strip()
        volume = subprocess.run("$HOME/spotify_control vget", shell=True, capture_output=True).stdout.decode("utf-8").strip()
        volume = int(float(volume)*100)
        return "{} 🎵{}%".format(music_name, volume)
    except:
        return "Spotify Closed"

def print_line(message):
    """ Non-buffered printing to stdout. """
    sys.stdout.write(message + '\n')
    sys.stdout.flush()

def read_line():
    """ Interrupted respecting reader for stdin. """
    # try reading a line, removing any extra whitespace
    try:
        line = sys.stdin.readline().strip()
        # i3status sends EOF, or an empty line
        if not line:
            sys.exit(3)
        return line
    # exit on ctrl-c
    except KeyboardInterrupt:
        sys.exit()

if __name__ == '__main__':
    # print something if debug is on
    args = sys.argv[1:]
    if len(args) > 0 and "-d" in args:
        print(get_temperature_status())

    # print(get_headset_battery_status())
    # Skip the first line which contains the version header.
    print_line(read_line())

    # The second line contains the start of the infinite array.
    print_line(read_line())

    while True:
        line, prefix = read_line(), ''
        # ignore comma at start of lines
        if line.startswith(','):
            line, prefix = line[1:], ','

        j = json.loads(line)
        # insert information into the start of the json, but could be anywhere
        # CHANGE THIS LINE TO INSERT SOMETHING ELSE
        j.insert(0, {'full_text': '%s' % music()})
        j.insert(0, {'full_text' : '%s' % notification_status(), 'name' : 'gov'})
        j.insert(-1, get_headset_battery_status())
        j.insert(-2, get_temperature_status())
        # and echo back new encoded json
        print_line(prefix+json.dumps(j))
