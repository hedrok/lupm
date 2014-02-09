#!/usr/bin/perl

# This script builds all packages in chapter 6

use Term::ANSIColor;
use YAML::XS;
use Data::Dumper;
use strict;
use warnings;

# Fully automated build of chapter 6 of lfs

sub error {
    my $message = shift(@_);
    print STDERR colored ['bold red'], "Error: $message\n";
    exit(1);
}
sub message {
    my $message = shift(@_);
    print colored ['bold yellow'], "$message\n";
}
sub status {
    my $message = shift(@_);
    print colored ['bold green'], "$message\n";
}

my $scriptdir = "/usr/src/lupm";
my $logdir = "/usr/src/lupm/logs";
my $builddir = "/usr/src";
my $statusFilename = "$logdir/chapter6.yaml";

my $status = undef;
if (-f$statusFilename) {
    $status = YAML::XS::LoadFile($statusFilename);
} else {
    $status = YAML::XS::Load('');
}

sub buildPackage {
    my $packageconfigname = shift(@_);
    if (exists $status->{"$packageconfigname"} && $status->{"$packageconfigname"} == 1) {
        message("$packageconfigname already done");
        return;
    }
    system ();
    print("$scriptdir/lupm/lupm $packageName\n");
    system("$scriptdir/lupm/lupm $packageName") == 0
        or error("Failed to build package $packageName");

    $status->{"$packageconfigname"} = 1;
    YAML::XS::DumpFile($statusFilename, $status);
}

buildPackage('linux-headers');
buildPackage('man-pages');
buildPackage('glibc');
buildPackage('tzdata');
buildPackage('adjust-toolchain');
buildPackage('zlib');
buildPackage('file');
buildPackage('binutils');
buildPackage('gmp');
buildPackage('mpfr');
buildPackage('mpc');
buildPackage('gcc');
buildPackage('sed');
buildPackage('bzip2');
buildPackage('pkg-config');
buildPackage('ncurses');
buildPackage('attr'); #systemd requirement
buildPackage('acl'); #systemd requirement
buildPackage('libcap'); #systemd requirement
buildPackage('shadow');
buildPackage('util-linux');
buildPackage('psmisc');
buildPackage('procps-ng');
buildPackage('e2fsprogs');
buildPackage('coreutils');
buildPackage('iana-etc');
buildPackage('m4');
buildPackage('flex');
buildPackage('bison');
buildPackage('grep');
buildPackage('readline');
buildPackage('bash');
buildPackage('bc');
buildPackage('libtool');
buildPackage('gdbm');
buildPackage('expat');
buildPackage('inetutils');
buildPackage('perl');
buildPackage('perl-module-libyaml');
buildPackage('perl-module-xml-parser');
buildPackage('autoconf');
buildPackage('automake');
buildPackage('diffutils');
buildPackage('gawk');
buildPackage('findutils');
buildPackage('gettext');
buildPackage('intltool');
buildPackage('gperf');
buildPackage('groff');
buildPackage('xz');
buildPackage('grub');
buildPackage('less');
buildPackage('gzip');
buildPackage('iproute2');
buildPackage('check');
buildPackage('kbd');
buildPackage('kmod');
buildPackage('libpipeline');
buildPackage('make');
buildPackage('man-db');
buildPackage('patch');
# part of dbus package
buildPackage('libdbus');
buildPackage('systemd');
buildPackage('dbus');
buildPackage('tar');
buildPackage('texinfo');
buildPackage('vim');
buildPackage('openssl');
buildPackage('sslcerts');
buildPackage('wget');
#move /tools /tools-build
buildPackage('chapter5');

#chapter8
buildPackage('linux');
