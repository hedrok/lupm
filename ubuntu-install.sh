#!/bin/sh
#sudo cat >> /etc/apt/sources.list << "EOF"
#deb http://archive.ubuntu.com/ubuntu/ quantal universe
#deb-src http://archive.ubuntu.com/ubuntu/ quantal universe
#deb http://archive.ubuntu.com/ubuntu/ quantal-updates universe
#deb-src http://archive.ubuntu.com/ubuntu/ quantal-updates universe
#EOF
sudo apt-get update
sudo apt-get install screen bison gawk vim w3m texinfo libyaml-perl g++
