#!/bin/sh
PREFIX=/usr
groupadd xorginstall;
for d in \
         include/X11/extensions \
         include/X11/fonts \
         include/X11/dri \
         include/GL \
         include/GL/internal \
         include/xcb \
         include/X11 \
         share/X11 \
         share/X11/app-defaults \
         ; do
    mkdir -pv $PREFIX/$d/;
    lupm-dir.sh $PREFIX/$d/ xorginstall;
done;
#forbid installing locale files
mkdir -pv $PREFIX/share/X11/locale
