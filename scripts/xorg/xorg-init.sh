#!/bin/sh
groupadd xorginstall;
for d in extensions fonts dri; do
    mkdir -pv /usr/include/X11/$d/;
    lupm-dir.sh /usr/include/X11/$d/ xorginstall;
done;
lupm-dir.sh /usr/include/X11/ xorginstall;
