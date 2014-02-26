#!/bin/sh
set -e
for package in xtrans libX11 libXext libFS libICE libSM libXScrnSaver libXt libXmu libXpm libXaw libXfixes libXcomposite libXrender libXcursor libXdamage libfontenc libXfont libXft libXi libXinerama libXrandr libXres libXtst libXv libXvMC libXxf86dga libXxf86vm libdmx libpciaccess libxkbfile libxshmfence; do
    filename="xorg-$(echo $package | awk '{print tolower($0)}')";
    extraconfig='';
    preconfigure='';
    case $package in
        libXfont )
            extraconfig="
                 --disable-devel-docs";
        ;;
        libXft )
            preconfigure="
    - preconfigure: sed -i 's#<freetype/#<freetype2/#' src/xftglyphs.c";
        ;;
        #libXt-[0-9]* )
        #  extraconfig='--with-appdefaultdir=/etc/X11/app-defaults'
        #;;
    esac
cat > ~/configs/${filename}.yaml << EOF
name: $package
installgroups: install,xorginstall
description: Xorg library part
download:
    - link: ftp://ftp.x.org/pub/individual/lib/
build:$preconfigure
    - configure: --prefix=\$PREFIX
                 --disable-static$extraconfig
    - make: ~
    - install: ~
EOF
done;
