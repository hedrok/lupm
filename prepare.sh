#!/bin/sh
. ./config.sh

./init-lfs-user.sh
#. ~/.bashrc

./check-host.pl &&
./check-partition.pl $LFS_PARTITION &&
mkdir -p $LFS/tools $LFS/tools-build &&
./check-yaml.pl &&
$SUDO ln -svf $LFS/tools / &&
echo "Done"
