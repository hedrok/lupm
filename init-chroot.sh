#!/bin/sh
set -e

export LFS=/mnt/lfs

chroot "$LFS" /usr/bin/env -i \
   HOME=/root                  \
   TERM="$TERM"                \
   MAKEFLAGS='-j 6'            \
   PS1='\u:\w\$ '              \
   PATH=/usr/src/scripts/lupm/:/bin:/usr/bin:/sbin:/usr/sbin \
   /bin/bash --login +h
