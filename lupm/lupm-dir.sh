#!/bin/sh
group=install
if [ "x" != "x$2" ]; then
    group=$2
fi
chgrp -v $group $1
chmod -v ug=rwx,o=rxt $1
