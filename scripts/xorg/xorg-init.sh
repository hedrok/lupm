#!/bin/sh
groupadd xorginstall;
for d in X11/extensions X11/fonts X11/dri xcb X11; do
    mkdir -pv /usr/include/$d/;
    lupm-dir.sh /usr/include/$d/ xorginstall;
done;
