#!/bin/sh
set -e
for package in bigreqsproto compositeproto damageproto dmxproto dri2proto dri3proto fixesproto fontsproto glproto inputproto kbproto randrproto recordproto renderproto resourceproto scrnsaverproto videoproto xcmiscproto xextproto xf86bigfontproto xf86dgaproto xf86driproto xf86vidmodeproto xineramaproto xproto presentproto; do
cat > ~/configs/xorg-${package}.yaml << EOF
name: $package
installgroups: install,xorginstall
description: Xorg protocol header part
download:
    - link: ftp://ftp.x.org/pub/individual/proto/
build:
    - configure: --prefix=\$PREFIX
    - install: ~
EOF
done;
