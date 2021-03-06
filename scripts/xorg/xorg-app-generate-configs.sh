#!/bin/sh
set -e
for package in $(cat /usr/src/lupm/scripts/xorg/app-list.txt) ; do
    filename="xorg-$(echo $package | awk '{print tolower($0)}')";
    preconfigure='';
    case $package in
      luit )
        preconfigure='
    - preconfigure: sed -i -e "s@#ifdef HAVE_CONFIG_H@#ifdef _XOPEN_SOURCE\n#  undef _XOPEN_SOURCE\n#  define _XOPEN_SOURCE 600\n#endif\n\n&@" sys.c;';
      ;;
    esac
cat > ~/configs/${filename}.yaml << EOF
# Don't edit! Generated by ~/scripts/xorg/xorg-app-generate-configs.sh
name: $package
installgroups: install,xorginstall
description: Xorg application
download:
    - link: ftp://ftp.x.org/pub/individual/app/
build:$preconfigure
    - configure: --prefix=\$PREFIX
                 --disable-static
    - make: ~
    - install: ~
EOF
done;
