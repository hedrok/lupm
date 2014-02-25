#!/bin/sh
set -e
./xorg-init.sh;
lupm util-macros;
./xorg-proto-install.sh;
lupm makedepend;
lupm xorg-libxau;
lupm xorg-libxdmcp;
lupm xorg-xcb-proto;
lupm xorg-libxcb;
./xorg-lib-install.sh;
lupm xorg-xcb-util;
lupm xorg-xcb-util-image;
lupm xorg-xcb-util-keysyms;
lupm xorg-xcb-util-renderutil;
lupm xorg-xcb-util-wm;
