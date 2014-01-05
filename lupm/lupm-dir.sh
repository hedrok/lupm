#!/bin/sh
chgrp -v install $1
chmod -v ug=rwx,o=rxt $1
