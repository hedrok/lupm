#!/bin/sh
set -e
for package in $(cat /usr/src/lupm/scripts/xorg/font-list.txt) ; do
    username='';
    case $package in
        font-bh-lucidatypewriter-100dpi )
            username="
username: xorg-lucidatypewriter100dpi";
        ;;
        font-bh-lucidatypewriter-75dpi )
            username="
username: xorg-lucidatypewriter75dpi";
        ;;
        font-bh-type1 )
            preconfigure='
    - preconfigure: sed -i "/\t@rm -f/d" Makefile.am;
                    autoreconf -fi;';
        ;;
    esac;

    filename="xorg-$(echo $package | awk '{print tolower($0)}')";
cat > ~/configs/${filename}.yaml << EOF
# Don't edit! Generated by ~/scripts/xorg/xorg-font-generate-configs.sh
name: $package$username
installgroups: install,xorginstall
description: Xorg font
download:
    - link: ftp://ftp.x.org/pub/individual/font/
build:$preconfigure
    - configure: --prefix=\$PREFIX
                 --disable-static
    - make: ~
    - install: ~
EOF
done;
