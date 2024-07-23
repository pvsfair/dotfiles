#!/bin/bash

for x in {01..12}
do
  nitrogen --set-zoom-fill --random ~/Imagens/Walpapers/$x* --head=0 > /dev/null 2>&1
done

