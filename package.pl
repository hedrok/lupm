#!/usr/bin/perl

# Basic algo and structure:
# Each package has it's own dir, during chapter 5 it is directory
# under sources with package name, during chapter 6 and BLFS it is
# package user's directory.
#
# hierarchy:
# download/list.html
# download/version.yaml
#   filetype=tar.bz2
#   packagename=binutils
#   extra:
#       -name: bla
#       -link: url
#       -exportvar: BLA_ARCHIVE
#       -name: bar
#       -link: urlbar
#       -exportvar: BAR_ARCHIVE
# download/archive.tar.bz2
# source/ (unarchived source)
# build/ (build directory)
# logs/configure.log
# logs/make.log
# logs/install.log
# status.yaml
# config.yaml
#name: package-name
#download:
#    - name: ~ (default: package-name)
#      method: wget/wget-folders/git/svn
#      link: url
#    - name: ~ (default: package-name)
#      method: wget/wget-folders/git/svn
#      link: url
#    - name: ~ (default: package-name)
#      method: wget/wget-folders/git/svn
#      link: url

# Default 'target' is "build".
# Any number of arbitrary named targets can be made,

# Command line arguments:
# -d package directory (default - current directory)
# -c config file (default - config.yaml in package directory, if relative - it will be relative
#                 to package directory)
# update [target] - checks for newer version, if available, runs "clean" and target (default build)
# clean [target] - delete everything for target (default cleans all targets but not downloads)
# fullclean - delete all files produced by package.pl (all targets and downloads)
# [target] - build traget (default - download)

#build:
#    method: autoconf/configure/cmake/scons/
#    preconfigure: any_commands run in source tree
#    configure: exportvars: CFLAGS="-O3"
#               command: $PACKAGE_SRCDIR/specialconfigure
#               params: --sysconfdir=/etc/
#    premake: any commands run in build tree
#    make: exportvars: CFLAGS="-O3"
#          target:
#    test: any commands run after make in build tree
#    preinstall: any commands run after test in build tree
#    install: exportvars: DEST="/usr"
#    postinstall: any commands run after install in build tree

#Each download export vars NAME_SRC_DIR, and creates:
#$status->{'downloads'}{'name'}{'srcdir'} - extracted or synced source tree
#$status->{'downloads'}{'name'}{'version'} - version of sources (like "-3.2.2" in archive case, revision in git/svn)
#$status->{'downloads'}{'name'}{'archive'} - full path to archive (or none in case of none)
#$status->{'downloads'}{'name'}{'filetype'} - filetype of archive (or none in case of none)
#
#All other items are pretty simple, but all of them make logs:
#logs/preconfigure.log
#logs/configure.log
#logs/premake.log
#logs/make.log
#logs/test.log
#logs/preinstall.log
#logs/install.log
#logs/postinstall.log
#
#preconfigure, premake, preinstall and postinstall just run commands and save logs
#Currently only configure is supported:
#configure: exportvars $srcdir/configure $params
#make: exportvars make $target
#install: exportvars make install
#
#So functions:
#getLatestWgetLink($name, $link, $pattern);
#extract($filename, $filetype);
#download($name, $method, $link);
#runLoggedCommand($dir, $command, $name, $before = '', $after = '');
#    - download: 
#         method: wget/git/svn
#         link: http://ftp.gnu.org/gnu/binutils
#    - build:
#         method: autoconf/configure/make/scons/cmake
#         pre-configure: ~
#         configure: ~
#         pre-make: ~
#         make: ~
#    - install: ~
# status:
#  version: 3.2.1
#  filetype: tar.bz2 tar.xz2
#  downloaded:
#  extracted:
#  configured:
#  built:
#  installed:

use YAML::XS;
use Data::Dumper;
use v5.14;

my $packagedir = $ARGV[0];
if (!(-d $packagedir)) {
    print "Package dir '$packagedir' should be directory";
    exit 1;
}

my $config = YAML::XS::LoadFile("$packagedir/config.yaml");
my $status = undef;
if (-f "$packagedir/status.yaml") {
    $status = YAML::XS::LoadFile("$packagedir/status.yaml");
} else {
    my $hash = "version: ~";
    $status = YAML::XS::Load($hash);
}

sub clean { #{{{
    my $stage = shift(@_);
    given ($stage) {
        when ([undef, '', 'download']) {
            `rm -rf status.pl download source build logs`;
        }
        when ('source') {
            `rm -rf source build logs`;
        }
        when ('build') {
            `rm -rf build logs`;
        }
        default {
            `rm -rf download soure build logs status.pl`
        }
    }
} #}}}
sub error {
    my $message = shift(@_);
    print "Error: $message\n";
    exit(1);
}
sub message {
    my $message = shift(@_);
    print "$message\n";
}
sub status {
    my $message = shift(@_);
    print "Status: $message\n";
}

sub fixRelativeLink { #{{{
    my $absoluteLink = shift(@_);
    my $possiblyRelativeLink = shift(@_);
    my $link = $possiblyRelativeLink;
    if ($possiblyRelativeLink !~ m#^[a-z]+://#) {
        $absoluteLink =~ s#\?.*$##;
        print "abs1: $absoluteLink\n";
        $absoluteLink =~ s#/[^/]+\.[a-z]+(\?.*)?$#/#;
        if ($absoluteLink !~ m#/$#) {
            $absoluteLink .= '/';
        }
        $link = $absoluteLink . $possiblyRelativeLink;
    }
    return $link;
} #}}}
sub testFixRelativeLink {
    my $abs = 'http://wrong/';
    my $rel = 'ftp://correct.com/a.tar.bz2';
    my $res = fixRelativeLink($abs, $rel);
    if (!($res eq $rel)) {
        error("Test failed: fixRelativeLink($abs, $rel) = $res\n");
    }
}
testFixRelativeLink();

sub getLinkFolderWget { #{{{
    my $link = shift(@_);
    my $package = shift(@_);
    my $downloaddir = "$packagedir/download";
    system("mkdir -p $downloaddir") == 0
        or error("Couldn't create directory $downloaddir");
    my $tmpfile = "$downloaddir/$package-list-folder";
    message("Trying to get $link to $tmpfile\n");
    system("wget -O $tmpfile \"$link\"") == 0
        or error("Couldn't download list from '$link' to '$tmpfile'\n");
    my $flink =`sed -n "s/^.*href=[\\"']\\([^'\\"]*$package-[0-9.]\\+\\/\\?\\)[\\"'].*\$/\\1/p" $tmpfile | sort -V | tail -n 1`;
    $flink =~ s/^\s+//;
    $flink =~ s/\s+$//;
    if ($flink eq '') {
        error("Couldn't get version of $package (folder method).\n");
    }
    $flink = fixRelativeLink($link, $flink);
    print "got link: $link, flink: $flink\n";
    return $flink;
} #}}}
sub getVersionWget { #($link, $package, $downloaddir) #{{{
    my $link = shift(@_);
    my $package = shift(@_);
    my $downloaddir = "$packagedir/download";
    system("mkdir -p $downloaddir") == 0
        or error("Couldn't create directory $downloaddir");
    my $tmpfile = "$downloaddir/$package-list";
    message("Trying to get $link to $tmpfile\n");
    system("wget -O $tmpfile \"$link\"") == 0
        or error("Couldn't download list from '$link' to '$tmpfile'\n");
    my $packageFilename = '';
    my $filetype = '';
    my @filetypes = ('tar.xz', 'tar.bz2', 'tar.gz', 'zip');
    my $downloadLink = '';
    foreach (@filetypes) {
        $downloadLink =`sed -n "s/^.*href=[\\"']\\([^'\\"]*$package-[0-9.]\\+\.$_\\)[\\"'].*\$/\\1/p" $tmpfile | sort -V | tail -n 1`;
        $downloadLink  =~ s/^\s+//;
        $downloadLink  =~ s/\s+$//;
        if (!($downloadLink  eq "" )) {
            $filetype = $_;
            last;
        }
    }
    if ($filetype eq '') {
        error("Couldn't get version of $package.\n");
    }
    $downloadLink = fixRelativeLink($link, $downloadLink);
    $downloadLink =~ /$package([0-9.-]*)\.$filetype/;
    my $version = $1;
    $packageFilename = "$package$version.$filetype";

    return ($packageFilename, $filetype, $downloadLink, $version);
} #}}}
sub extract { #($archivename, $filetype, $srcdir) #{{{
    my $archivename = shift(@_);
    my $filetype = shift(@_);
    my $srcdir = shift(@_);
    system("mkdir -p '$srcdir'") == 0
        or error("Couldn't create directory '$srcdir'");
    for ($filetype) {
        if (/tar\.(bz2|xz|gz)$/) {
            system("tar -C '$srcdir' -xvf '$archivename'") == 0
                or error("Couldn't extract $archivename");
            last;
        }
        if (/\.zip$/) {
            system("unzip -d '$srcdir' '$archivename'") == 0
                or error("Couldn't extract $archivename");
            last;
        }
        error("Unknown filetype: $filetype");
    }
}#}}}

if (!exists $status->{'downloaded'}) {
    my $packagename = $config->{'name'};
    status("Trying to download $packagename");
    foreach (@{$config->{'download'}}) {
        my $name = $_->{'name'};
        my $link = $_->{'link'};
        my $method = $_->{'method'};
        my $archivename = undef;
        my $filetype = undef;
        my $srcdir = undef;
        my $version = undef;
        if (!$name) {
            $name = $packagename;
        }
        if (!$method) {
            $method = 'wget';
        }
        if (!$link) {
            error("No link provided for download of $name");
        }
        if ($status->{'downloads'}{$name}{'downloaded'} eq '1') {
            next;
        }

        print "Method: $method\n";
        if ($method eq 'wget-folder') {
            print "Using wget-folder\n";
            $link = getLinkFolderWget($link, $name);
            if (!$link) {
                error("Couldn't get last version from folder $link, $name");
            }
            status("Latest version link: $link");
            $method = 'wget';
        }
        if ($method eq 'wget') {
            print "Using wget\n";
            my $packageFilename;
            ($packageFilename, $filetype, $link, $version) = getVersionWget($link, $name);
            if (!$packageFilename) {
                error("Error getting version of $name by link $link.");
            }
            $archivename = "$packagedir/download/$packageFilename";
            system("wget \"$link\" -c -O \"$archivename\"") == 0
                or error("Couldn't download $link (package: $name).\n");
            $srcdir = "$packagedir/source";
            message("Downloaded $archivename");
            extract($archivename, $filetype, $srcdir);
            message("Extracted $archivename");
        } else {
            error("Unsupported download method $method");
        }
        $status->{'downloads'}{$name}{'srcdir'} = "$srcdir/$name$version";
        $status->{'downloads'}{$name}{'version'} = $version;
        $status->{'downloads'}{$name}{'archive'} = $archivename;
        $status->{'downloads'}{$name}{'filetype'} = $filetype;
        $status->{'downloads'}{$name}{'downloaded'} = '1';
        YAML::XS::DumpFile("$packagedir/status.yaml", $status);
    }
    status("Downloaded $packagename successfully\n");
    $status->{'downloaded'} = 1;
    YAML::XS::DumpFile("$packagedir/status.yaml", $status);
}
sub exportDownloadVariables {
    foreach my $packagename (keys %{$status->{'downloads'}}) {
        my $varname = "\U${packagename}_SRC_DIR";
        $ENV{$varname} = $status->{'downloads'}{$packagename}{'srcdir'};
        if ($packagename == $config->{'name'}) {
            $ENV{'PACKAGE_SRCDIR'} = $status->{'downloads'}{$packagename}{'srcdir'};
        }
    }
}
exportDownloadVariables();

#preconfigure, premake, preinstall and postinstall just run commands and save logs
#Currently only configure is supported:
#configure: exportvars $srcdir/configure $params
#make: exportvars make $target
#install: exportvars make install

my @stagesList = ('autoconf',
           'preconfigure',
           'configure',
           'premake',
           'make',
           'test',
           'install',
           'postinstall');
my $stagesCommands = {
    'autoconf' => {
        'dir' => 'src',
        'command' => '$PACKAGE_SRCDIR/autoconf'
    },
    'preconfigure' => {
        'dir' => 'src'
    },
    'configure' => {
        'command' => '$PACKAGE_SRCDIR/configure'
    },
    'premake' => {},
    'make' => {
        'command' => 'make'
    },
    'test' => {},
    'install' => {
        'command' => 'make install'
    },
    'postinstall' => {}
};

sub processStage {
    my $name = shift(@_);
    my $conf = shift(@_);
    my $stage = shift(@_);
    my $command = '';
    # possible stage keys:
    # dir - in what directory to run: src/build
    # command

    if ($status->{$name}) {
        return;
    }
    print "Running phase $name\n";

    my $srcdir = $status->{'downloads'}{$config->{'name'}}{'srcdir'};
    my $builddir = "$packagedir/build";
    my $logdir = "$packagedir/logs";
    my $logfile = "$logdir/$name.log";
    system("mkdir -p $logdir") == 0
        or error("Couldn't create directory $logdir");

    my $dir = '';
    
    if ($stage->{'dir'} eq 'src') {
        $dir = $srcdir;
    } else {
        $dir = $builddir;
        system("mkdir -p $builddir") == 0
            or error("Couldn't create directory $builddir");
    }
    chdir($dir);
    if ($stage->{'command'}) {
        $command = $stage->{'command'};
    }
    if (ref($conf)) {
        if ($conf->{'exportvars'}) {
            $command = $conf->{'exportvars'} . " $command";
        }
        if ($conf->{'params'}) {
            $command .= " $conf->{'params'}";
        }
    } else {
        $command .= " $conf";
    }

    my $scriptfile = "$logdir/$name.sh";
    open(SCRIPT, '>', $scriptfile)
        or error("Couldn't create $scriptfile\n");
    print SCRIPT "#!/bin/bash\n";
    print SCRIPT "set -e\n";
    print SCRIPT "{\n";
    print SCRIPT "$command\n";
    print SCRIPT "} 2>&1 | tee $logfile\n";
    print SCRIPT "exit \${PIPESTATUS[0]}\n";
    close SCRIPT;
    system("chmod +x $scriptfile") == 0
        or error("Couldn't make '$scriptfile' executable");

    system("$scriptfile") == 0
        or error("Failure running $name phase");

    $status->{$name} = '1';
    YAML::XS::DumpFile("$packagedir/status.yaml", $status);
}

foreach (@stagesList) {
    if (exists $config->{'build'}{$_}) {
        processStage($_, $config->{'build'}{$_}, $stagesCommands->{$_});
    }
}
=comment

#premake: any commands run in build tree
#    make: exportvars: CFLAGS="-O3"
#          target:
#    test: any commands run after make in build tree
#    preinstall: any commands run after test in build tree
#    install: exportvars: DEST="/usr"
#    postinstall: any commands run after install in build tree
if (!exists $status->{'configured'}) {
    clean('build');
    if ($config->{'build'}{'method'} != 'configure') {
        die("Unkown build method: " . $config->{'build'}{'method'});
    }
    my $builddir = "$packagedir/build";
    my $logdir = "$packagedir/logs";
    system("mkdir -p $builddir") == 0
        or die("Couldn't create build directory '$builddir'\n");
    system("mkdir -p $logdir") == 0
        or die("Couldn't create build directory '$logdir'\n");
    my $logfile = "$logdir/configure.log";

    my $configure = $config->{'build'}{'configure'};
    my $configurevars = $config->{'build'}{'configvars'};
    my $prefix = $config->{'build'}{'prefix'};
    my $foldername = $config->{'name'} . $status->{'version'};
    if ($prefix) {
        $configurevars = $configurevars . " --prefix=$prefix";
    }

    chdir("$packagedir/source/$foldername");
    my $exportvars = $status->{'exportvars'};
    my $preconfigure = $exportvars . $config->{'build'}{'preconfigure'};
    if ($preconfigure) {
        system($preconfigure) == 0
            or die("Failed to run preconfigure command: $preconfigure");
    }

    chdir($builddir);
    system("$configurevars ../source/$foldername/configure $configure 2>&1 | tee $logfile ") == 0
        or die ("Configure failed.\n");
    $status->{'configured'} = '1';
    YAML::XS::DumpFile("$packagedir/status.yaml", $status);
} else {
    print "Configured\n";
}
