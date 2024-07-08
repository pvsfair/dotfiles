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

SCREENSHOT="scrot $IMAGE" # 0.46s

# Alternate screenshot method with imagemagick. NOTE: it is much slower
# SCREENSHOT="import -window root $IMAGE" # 1.35s

# Here are some imagemagick blur types
# Uncomment one to use, if you have multiple, the last one will be used

# All options are here: http://www.imagemagick.org/Usage/blur/#blur_args
BLURTYPE="0x8" # 7.52s
#BLURTYPE="0x2" # 4.39s
#BLURTYPE="5x2" # 3.80s
# BLURTYPE="2x8" # 2.90s
#BLURTYPE="2x3" # 2.92s

# Get the screenshot, add the blur and lock the screen with it
$SCREENSHOT
SIZE=`identify $IMAGE | cut -f 3 -d " "`
echo $SIZE
R=$((RANDOM % 2))
case $R in
  # 0)
  #   # head injury lock
  #   convert $IMAGE \( -size $SIZE gradient: -rotate -270 \) \( -size 1x1440 gradient: -spread 128 -scale $SIZE\! \) -compose Distort -define compose:args='' -composite $IMAGE
  #   ;;
  0)
    # pixelated lock
    convert $IMAGE -sample 7% -scale $SIZE\! $IMAGE
    ;;
  *)
    # blurred lock
    convert $IMAGE -blur $BLURTYPE $IMAGE
esac
# xdg-open $IMAGE
i3lock -i $IMAGE 
# 1440 4480
# rm $IMAGE
