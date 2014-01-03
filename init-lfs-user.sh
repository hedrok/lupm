#!/bin/sh
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
MAKEFLAGS='-j 6'
PATH=/tools/bin:/bin:/usr/bin
alias ls="ls --color"
export LFS LC_ALL LFS_TGT PATH MAKEFLAGS
EOF
cat > ~/.vimrc << "EOF"
set switchbuf="useopen,usetab,newtab"
set hidden
set ruler 
set expandtab
set shiftwidth=4
set softtabstop=4
set tabstop=4
set number
set completeopt+=longest
set encoding=utf-8
set termencoding=utf8 
syntax enable
set backspace=indent,eol,start 
set wildmenu
set wildmode=list:longest
set wcm=<Tab> 
set hlsearch
set cindent
set foldmethod=marker
EOF
cat > ~/.screenrc << "EOF"
# C-a :source .screenrc

startup_message off
vbell off
autodetach on
altscreen on
shelltitle "$ |w"
defscrollback 10000
defutf8 on
nonblock on

hardstatus alwayslastline
bindkey -a -k fe stuff ^M
hardstatus string '%{Yk}%c %{-b Ck}%-w%{Gk}%n %t%{-b Ck}%+w'
EOF
