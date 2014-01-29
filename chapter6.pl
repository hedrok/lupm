#!/usr/bin/perl

# This script builds all packages in chapter 6
# Unlike chapter 5, User Package Management is used.
#
# Each package is controlled by .yaml file.
# This file can contain following:
#
# package:
#   name: package-name
#   installgroups: install
#   description: something about package
#   prefix: /usr
#   target: build
#   configname: ~
#   root-before: ~
#   root-after: ~
#
# Default values are provided above.
# The only required field is name
#
# Default for configfile is yaml file itself
#
# Steps:
# 1) Create user/group for package
# 2) Add user to all installgroups, delete from all other groups
# 3) launch lfs-package from user on configfile, what should we do with prefix?

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

my $scriptdir = "/usr/src/scripts";
my $logdir = "/usr/src/scripts/logs";
my $builddir = "/usr/src";
my $statusFilename = "$builddir/chapter6.yaml";

my $status = undef;
if (-f$statusFilename) {
    $status = YAML::XS::LoadFile($statusFilename);
} else {
    $status = YAML::XS::Load('');
}

sub addGroup {
    my $group = shift(@_);

    print ("groupadd '$group'\n");
    system("groupadd '$group'");
    if ($? == -1) {
        error ("Could not create group $group: " + ($? & 127));
    }
    if (($? & 127) != 0 && ($? & 127) != 9) {
        error ("Could not create group $group: " + ($? & 127));
    }
}

sub buildPackage {
    my $packageconfigname = shift(@_);
    if (exists $status->{"$packageconfigname"} && $status->{"$packageconfigname"} == 1) {
        message("$packageconfigname already done");
        return;
    }
    my $packageconfpath = "$scriptdir/packages/$packageconfigname.yaml";
    if (not -f $packageconfpath) {
        $packageconfpath = "$scriptdir/configs/$packageconfigname.yaml";
        if (not -f $packageconfpath) {
            error "Could not load package config: $packageconfpath. No such file.";
        }
    }
    my $packageconfig = YAML::XS::LoadFile($packageconfpath);
    my $configpath = $packageconfpath;
    if (exists($packageconfig->{'configname'})) {
        $configpath = "$scriptdir/configs/$packageconfig->{'configname'}.yaml";
    }
    if (not -f$configpath) {
        error "Config file does not exist: $configpath";
    }
    my $installgroups = 'install';
    my $description = '';
    my $prefix = '/usr';
    my $target = 'build';
    my $root_before = '';
    my $root_after = '';

    if (exists($packageconfig->{'installgroups'})) {
        $installgroups = $packageconfig->{'installgroups'};
    }
    if (exists($packageconfig->{'description'})) {
        $description = $packageconfig->{'description'};
    }
    if (exists($packageconfig->{'prefix'})) {
        $prefix = $packageconfig->{'prefix'};
    }
    if (exists($packageconfig->{'target'})) {
        $target = $packageconfig->{'target'};
    }

    addGroup($packageconfigname);
    my @grouplist = split(',', $installgroups);
    for (@grouplist) {
        addGroup($_);
    }

    print ("useradd -m -k $scriptdir/lupm/skel -b $builddir -c '$description' -g '$packageconfigname' -G '$installgroups' '$packageconfigname'\n");
    system("useradd -m -k $scriptdir/lupm/skel -b $builddir -c '$description' -g '$packageconfigname' -G '$installgroups' '$packageconfigname'");
    if ($? == -1) {
        error ("Could not create user $packageconfigname: " + ($? & 127));
    }
    if (($? & 127) != 0 && ($? & 127) != 9) {
        error ("Could not create user $packageconfigname: " + ($? & 127));
    }

    $ENV{'PREFIX'} = $prefix;
#should be done in useradd
#    system("mkdir -vp $builddir/$packageconfigname") == 0
#        or error ("Could not create user home directory $builddir/$packageconfigname");
#    system("chown -R $packageconfigname:$packageconfigname $builddir/$packageconfigname") == 0
#        or error ("Could not chown home directory");

    if (exists($packageconfig->{'root-before'})) {
        print("$scriptdir/package.pl -p $prefix -d $builddir/$packageconfigname -c $configpath -t root-before -s $builddir/downloads --statusfilename=root-before.yaml\n");
        system("$scriptdir/package.pl -p $prefix -d $builddir/$packageconfigname -c $configpath -t root-before -s $builddir/downloads --statusfilename=root-before.yaml") == 0
            or error("Failed to build package $packageconfigname: root-before");
        system("chown -R $packageconfigname:$packageconfigname $builddir/$packageconfigname/targets") == 0
            or error ("Could not chown $builddir/$packageconfigname/targets directory");
    }

    print("su - -c '$scriptdir/package.pl -p $prefix -d $builddir/$packageconfigname -c $configpath -t $target -s $builddir/downloads' $packageconfigname\n");
    system("su - -c '$scriptdir/package.pl -p $prefix -d $builddir/$packageconfigname -c $configpath -t $target -s $builddir/downloads' $packageconfigname") == 0
        or error("Failed to build package $packageconfigname: $target");

    if (exists($packageconfig->{'root-after'})) {
        print("$scriptdir/package.pl -p $prefix -d $builddir/$packageconfigname -c $configpath -t root-after -s $builddir/downloads --statusfilename=root-after.yaml\n");
        system("$scriptdir/package.pl -p $prefix -d $builddir/$packageconfigname -c $configpath -t root-after -s $builddir/downloads --statusfilename=root-after.yaml") == 0
            or error("Failed to build package $packageconfigname: root-after");
        system("chown -R $packageconfigname:$packageconfigname $builddir/$packageconfigname/targets/root-after") == 0
            or error ("Could not chown $builddir/$packageconfigname/targets/root-after directory");
    }

    status("$packageconfigname: done");
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
buildPackage('attr');
buildPackage('acl');
buildPackage('libcap');
buildPackage('shadow');
buildPackage('util-linux');
buildPackage('psmisc');
buildPackage('procps-ng');
buildPackage('e2fsprogs');
buildPackage('coreutils');
