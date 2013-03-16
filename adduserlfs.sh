#!/bin/sh
. ./config.sh
groupadd lfs
echo "useradd -s /bin/bash -g lfs -m -k /dev/null -d $LFS/tools-build/lfs-home lfs"
useradd -s /bin/bash -g lfs -m -k /dev/null -d $LFS/tools-build/lfs-home lfs
usermod -a -G adm lfs
usermod -a -G sudo lfs
