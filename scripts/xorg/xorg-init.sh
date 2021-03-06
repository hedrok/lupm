#!/bin/sh
PREFIX=/usr
groupadd -f xorginstall;
groupadd -f fontinstall;
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
         share/X11/xorg.conf.d \
         share/fonts/X11 \
         etc/X11/app-defaults \
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
lupm-dir.sh $PREFIX/share/fonts fontinstall;

for f in \
         share/icons \
         share/icons/hicolor \
         share/icons/hicolor/16x16/apps \
         share/icons/hicolor/16x16/mimetypes \
         share/icons/hicolor/22x22/apps \
         share/icons/hicolor/22x22/mimetypes \
         share/icons/hicolor/24x24/apps \
         share/icons/hicolor/24x24/mimetypes \
         share/icons/hicolor/32x32/apps \
         share/icons/hicolor/32x32/mimetypes \
         share/icons/hicolor/48x48/apps \
         share/icons/hicolor/48x48/mimetypes \
         share/icons/hicolor/128x128/apps \
         share/icons/hicolor/128x128/mimetypes \
         share/icons/hicolor/256x256/apps \
         share/icons/hicolor/256x256/mimetypes \
         share/icons/hicolor/scalable/apps \
         share/icons/hicolor/scalable/mimetypes \
         share/appdata \
         share/pixmaps \
         ; do
    mkdir -p $PREFIX/$f/;
    lupm-dir.sh $PREFIX/$f;
done;
