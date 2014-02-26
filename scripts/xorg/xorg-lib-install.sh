#!/bin/sh
set -e
for package in xtrans libX11 libXext libFS libICE libSM libXScrnSaver libXt libXmu libXpm libXaw libXfixes libXcomposite libXrender libXcursor libXdamage libfontenc libXfont libXft libXi libXinerama libXrandr libXres libXtst libXv libXvMC libXxf86dga libXxf86vm libdmx libpciaccess libxkbfile libxshmfence; do
    filename="xorg-$(echo $package | awk '{print tolower($0)}')";
    lupm $filename;
done;
