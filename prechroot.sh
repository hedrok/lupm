#!/bin/sh
set -e

export LFS=/mnt/lfs

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys

if [ -h $LFS/dev/shm ]; then
    link=$(readlink $LFS/dev/shm)
    mkdir -p $LFS/$link
    mount -vt tmpfs shm $LFS/$link
    unset link
else
    mount -vt tmpfs shm $LFS/dev/shm
fi
