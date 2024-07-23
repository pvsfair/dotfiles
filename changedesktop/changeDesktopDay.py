import subprocess
from datetime import datetime
from astral import LocationInfo
from astral.sun import sun

#  40.258686,-7.5138956,15

l = LocationInfo("Covilha", "Castelo Branco", "Portugal", 40.258686, -7.5138956)

s = sun(l.observer, date=datetime.now())

def mapRange(x, in_min, in_max, out_min, out_max):
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min

def mapRangeRound(x, in_min, in_max, out_min, out_max):
    return round(mapRange(x, in_min, in_max, out_min, out_max))

command = "/usr/bin/nitrogen --set-zoom-fill --random ~/Imagens/Walpapers/{image:02d}* --head={monitor} >> /dev/null 2>&1"

sunrise = s["sunrise"].hour + (s["sunrise"].minute/60 + s["sunrise"].second/3600)
sunset = s["sunset"].hour + (s["sunset"].minute/60 + s["sunset"].second/3600)
numFilesDay = 9
numFilesTotal = 12
fileNum = 1
hour = datetime.now().hour + (datetime.now().minute/60 + datetime.now().second/3600)
# hour = 10
if hour > sunrise and hour < sunset:
    fileNum = mapRangeRound(hour, sunrise, sunset, 1, numFilesDay)
else:
    if hour < sunset:
        hour += 24
    fileNum = mapRangeRound(hour, sunset, 24+sunrise, numFilesDay+1, numFilesTotal)
for monitor in range(0, 2):
    cmdToRun=command.format(image=fileNum, monitor=monitor)
    r = subprocess.run(cmdToRun, shell=True, executable='/bin/bash')

