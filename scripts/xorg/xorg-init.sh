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
         share/fonts/X11 \
         ; do
    mkdir -pv $PREFIX/$d/;
    lupm-dir.sh $PREFIX/$d/ xorginstall;
done;
for f in \
         100dpi \
         75dpi \
         cyrillic \
         misc \
         Type1 \
         TTF \
         OTF \
         ; do
    dir=$PREFIX/share/fonts/X11/$f/
    mkdir -pv $dir
    lupm-dir.sh $dir xorginstall;
    chown -v root $dir;
    touch $dir/{fonts.dir,fonts.alias,fonts.scale};
    chmod -v 664 $dir/{fonts.dir,fonts.alias,fonts.scale};
    chgrp -v xorginstall $dir/{fonts.dir,fonts.alias,fonts.scale};
done;
#forbid installing locale files
mkdir -pv $PREFIX/share/X11/locale;
