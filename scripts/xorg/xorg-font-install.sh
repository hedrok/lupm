#!/bin/sh
set -e
for package in $(cat /usr/src/lupm/scripts/xorg/font-list.txt) ; do
    filename="xorg-$(echo $package | awk '{print tolower($0)}')";
    lupm $filename;
done;
