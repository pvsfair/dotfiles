#!/bin/bash

# i3lock blurred screen inspired by /u/patopop007 and the blog post
# http://plankenau.com/blog/post-10/gaussianlock

# Timings are on an Intel i7-2630QM @ 2.00GHz

# Dependencies:
# imagemagick
# i3lock
# scrot (optional but default)

IMAGE=/tmp/i3lock.png
rm $IMAGE

SCREENSHOT="scrot $IMAGE" # 0.26s

# Alternate screenshot method with imagemagick. NOTE: it is much slower
# SCREENSHOT="import -window root $IMAGE" # 1.35s

# Here are some imagemagick blur types
# Uncomment one to use, if you have multiple, the last one will be used

# All options are here: http://www.imagemagick.org/Usage/blur/#blur_args
BLURTYPE="0x8" # 1.41s
#BLURTYPE="0x2" # 0.60s
#BLURTYPE="5x2" # 0.53s
# BLURTYPE="2x8" # 0.38s
#BLURTYPE="2x3" # 0.37s

# Get the screenshot, add the blur and lock the screen with it
$SCREENSHOT
SIZE=`identify $IMAGE | cut -f 3 -d " "`
echo $SIZE
RSIZE=`echo $SIZE | awk -Fx '{print $2 "x" $1}'`
PSIZE=`echo $SIZE | awk -Fx '{print "1x" $2}'`
R=$((RANDOM % 5))
case $R in
  0)
    # head injury lock
    convert $IMAGE \( -size $RSIZE gradient: -rotate -270 \) \( -size $PSIZE gradient: -spread 128 -scale $SIZE\! \) -compose Distort -define compose:args='' -composite -flip $IMAGE #0.89
    ;;
  1 | 2)
    # pixelated lock
    convert $IMAGE -sample 7% -scale $SIZE\! $IMAGE #0.29s
    ;;
  *)
    # blurred lock
    convert $IMAGE -blur $BLURTYPE $IMAGE
esac
# xdg-open $IMAGE
i3lock -i $IMAGE -p win
# 1440 4480
# rm $IMAGE
sleep 10
while [ $(pgrep i3lock -x | wc -l ) -ne 0 ];
do
	xset dpms force off
	sleep 60
done
