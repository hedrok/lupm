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
