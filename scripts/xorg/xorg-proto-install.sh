#!/bin/bash
set -e
for package in bigreqsproto compositeproto damageproto dmxproto dri2proto fixesproto fontsproto glproto inputproto kbproto randrproto recordproto renderproto resourceproto scrnsaverproto videoproto xcmiscproto xextproto xf86bigfontproto xf86dgaproto xf86driproto xf86vidmodeproto xineramaproto xproto; do
    lupm xorg-$package;
done;
