#!/usr/bin/perl

use Term::ANSIColor;
use YAML::XS;
use Data::Dumper;
use strict;
use warnings;

# Fully automated build of chapter 5 of lfs

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

my $scriptdir = "$ENV{'LFS'}/scripts";
my $builddir = "$ENV{'LFS'}/tools-build";
my $statusFilename = "$builddir/chapter5.yaml";

my $status = undef;
if (-f$statusFilename) {
    $status = YAML::XS::LoadFile($statusFilename);
} else {
    $status = YAML::XS::Load('');
}

sub buildPackage {
    my $dirname = shift(@_);
    my $configname = shift(@_);
    my $target = shift(@_);
    if (exists $status->{"$dirname-$configname-$target"} && $status->{"$dirname-$configname-$target"} == 1) {
        message("$dirname $configname $target already done");
        return;
    }
    system("mkdir -p $builddir/$dirname") == 0
        or error("Couldn't create directory $builddir/$dirname");
    print("time $scriptdir/package.pl -d $builddir/$dirname -p /tools -c $scriptdir/configs/${configname}.yaml -t $target -s \$LFS/usr/src/downloads\n");
    system("time $scriptdir/package.pl -d $builddir/$dirname -p /tools -c $scriptdir/configs/${configname}.yaml -t $target -s \$LFS/usr/src/downloads") == 0
        or error("Failed to build package $dirname-$configname-$target");
    status("$dirname($target): done");
    $status->{"$dirname-$configname-$target"} = 1;
    YAML::XS::DumpFile($statusFilename, $status);
}

buildPackage('binutils-pass1', 'binutils', 'pass1');
buildPackage('gcc-pass1', 'gcc', 'pass1');
buildPackage('linux-headers', 'linux', 'headers');
buildPackage('glibc-pass1', 'glibc', 'pass1');
buildPackage('binutils-pass2', 'binutils', 'pass2');
buildPackage('gcc-pass2', 'gcc', 'pass2');
buildPackage('tcl', 'tcl', 'pass1');
buildPackage('expect', 'expect', 'pass1');
buildPackage('dejagnu', 'dejagnu', 'pass1');
buildPackage('check', 'check', 'build');
buildPackage('ncurses', 'ncurses', 'chapter5');
buildPackage('bash', 'bash', 'chapter5');
buildPackage('bzip2', 'bzip2', 'chapter5');
buildPackage('coreutils', 'coreutils', 'chapter5');
buildPackage('diffutils', 'diffutils', 'chapter5');
buildPackage('file', 'file', 'build');
buildPackage('findutils', 'findutils', 'chapter5');
buildPackage('gawk', 'gawk', 'chapter5');
buildPackage('gettext', 'gettext', 'chapter5');
buildPackage('grep', 'grep', 'pass1');
buildPackage('gzip', 'gzip', 'chapter5');
buildPackage('m4', 'm4', 'chapter5');
buildPackage('make', 'make', 'build');
buildPackage('patch', 'patch', 'build');
buildPackage('perl', 'perl', 'chapter5');
buildPackage('sed', 'sed', 'chapter5');
buildPackage('tar', 'tar', 'chapter5');
buildPackage('texinfo', 'texinfo', 'chapter5');
buildPackage('xz', 'xz', 'build');
# Additional to LFS (needed by my scripts and user package management):
buildPackage('coreutils-su', 'coreutils-su', 'build');
buildPackage('perl-module-libyaml', 'perl-module-libyaml', 'build');
buildPackage('perl-module-term-ansicolor', 'perl-module-term-ansicolor', 'build');
buildPackage('zlib', 'zlib', 'chapter5');
buildPackage('openssl', 'openssl', 'chapter5');
buildPackage('sslcerts', 'sslcerts', 'build');
buildPackage('wget', 'wget', 'chapter5');
