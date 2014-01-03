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
my $builddir = "/usr/src";
my $statusFilename = "$builddir/chapter6.yaml";

my $status = undef;
if (-f$statusFilename) {
    $status = YAML::XS::LoadFile($statusFilename);
} else {
    $status = YAML::XS::Load('');
}

sub buildPackage {
    my $configname = shift(@_);
    my $target = shift(@_);
    if (exists $status->{"$configname-$target"} && $status->{"$configname-$target"} == 1) {
        message("$configname $target already done");
        return;
    }
    system("mkdir -p $builddir/$dirname") == 0
        or error("Couldn't create directory $builddir/$dirname");
    print("time $scriptdir/package.pl -d $builddir/$dirname -c $scriptdir/configs/${configname}.yaml -t $target -s /usr/src/downloads\n");
    system("time $scriptdir/package.pl -d $builddir/$dirname -c $scriptdir/configs/${configname}.yaml -t $target -s /usr/src/downloads") == 0
        or error("Failed to build package $dirname-$configname-$target");
    status("$dirname($target): done");
    $status->{"$dirname-$configname-$target"} = 1;
    YAML::XS::DumpFile($statusFilename, $status);
}

buildPackage('linux', 'headers');
