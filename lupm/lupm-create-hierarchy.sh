#!/bin/sh

prefix=$1;
group=$2;
mkdir -pv $prefix/{bin,lib,include,share};
mkdir -pv $prefix/share/{info,locale,doc,man};
mkdir -pv $prefix/share/mime/packages
mkdir -pv $prefix/share/man/man{1,2,3,4,5,6,7,8};
case $(uname -m) in
    x86_64)
        ln -sv lib $prefix/lib64;
    ;;
esac
lupm-dir.sh $prefix/bin $group;
lupm-dir.sh $prefix/lib $group;
lupm-dir.sh $prefix/include $group;
lupm-dir.sh $prefix/share/info $group;
lupm-dir.sh $prefix/share/doc $group;
lupm-dir.sh $prefix/share/man/man1 $group;
lupm-dir.sh $prefix/share/man/man2 $group;
lupm-dir.sh $prefix/share/man/man3 $group;
lupm-dir.sh $prefix/share/man/man4 $group;
lupm-dir.sh $prefix/share/man/man5 $group;
lupm-dir.sh $prefix/share/man/man6 $group;
lupm-dir.sh $prefix/share/man/man7 $group;
lupm-dir.sh $prefix/share/man/man8 $group;
lupm-dir.sh $prefix/share/mime/packages $group;
