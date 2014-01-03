#!/bin/sh
set -e

export LFS=/mnt/lfs

chroot "$LFS" /tools/bin/env -i \
   HOME=/root                  \
   TERM="$TERM"                \
   PS1='\u:\w\$ '              \
   PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
   /tools/bin/bash --login +h
