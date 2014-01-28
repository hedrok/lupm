#!/usr/bin/perl

# Basic algo and structure:
# Each package has it's own dir, during chapter 5 it is directory
# under sources with package name, during chapter 6 and BLFS it is
# package user's directory.
#
# Config file has one download section and arbitrary number of
# target sections. Default target is "build". Also 'name' field is
# required as main name of package. Note that one config file can be used
# by several package users (e. g. binutils for avr/arm/x86).
#
# Download section:
# download:
#  - link: http://ftp.gnu.org/gnu/gcc
#    method: wget-folder
#  - name: mpfr
#    link: http://www.mpfr.org/mpfr-current/
#  - name: mpc
#    link: http://www.multiprecision.org/index.php?prog=mpc&page=download
#  - name: gmp
#    link: http://gmplib.org/
#  - name: tcl
#    method: sourceforge
#    suffix = '-src'
#  - name: bash-patches
#    method: wget-multiple
#    link:
#        eval: print "http://ftp.gnu.org/gnu/bash/bash" . $status->{'downloads'}{'bash'}{'version'} . "-patches/"
#    re: <a href="\\(bash[0-9]\\+-[0-9]\+\\)">
#
# Each item of download section should be a hash. Keys 'link', 'method' and 'name'
# are recognised. Default method is 'wget', default 'name' is package name.
# Currently recognised methods:
#   wget: gets link, searches for latest version of package there, downloads it.
#   wget-folder: same as wget, but searches for folders of package, than calls
#                wget method.
#   sourceforge:
#                http://sourceforge.net/api/project/name/tcl/json
#                Get from that link project id, use it to find lates package:
#                http://sourceforge.net/api/file/index/project-id/10894/json
#                Get from this link
#                'http://sourceforge.net/projects/tcl/files/Tcl/8.6.0/tcl-core8.6.0-src.tar.gz/download'
#                -src?..
#                 packagesuffix, versionsuffix
#   wget-multiple: tough one. Really needed for bash patches only right now. It needs not only download all patches,
#                  it should write list of all patches to $status->{'downloads'}{'name'} On update it should
#                  check whether there is some changes in file set that match regular expression.
#
# Planned methods are: git, svn, fixed
#
# Each download exports variable NAME_SRC_DIR, and creates (except wget-multiple)
# $status->{'downloads'}{'name'}{'srcdir'} - extracted or synced source tree
# $status->{'downloads'}{'name'}{'version'} - version of sources (like "-3.2.2" in archive case, revision in git/svn)
# $status->{'downloads'}{'name'}{'archive'} - full path to archive (or none in case of none)
# $status->{'downloads'}{'name'}{'filetype'} - filetype of archive (or none in case of none)
#
# wget-multiple has completely another structure (it is used fot patches currently, so nothing is extracted):
# $status->{'downloads'}{'name'} is list of hashes with kesy 'filename' and 'path'

# Default 'target' is "build".
# Any number of arbitrary named targets can be made,
# Each target consists of list of 'stages'. E.g.:
# build:
#    - preconfigure:
#    - configure: --sysconfdir=/etc/
#    - premake: any commands run in build tree
#    - make:
#          exportvars: CFLAGS="-O3"
#          target: headers
#    - test: make test
#    - fullsample:
#         vars: VAR=23
#         command: echo $VAR
#         params: "'And this'"
#         dir: src
#    - preinstall: any commands run after test in build tree
#    - install: ~
#    - postinstall: any commands run after install in build tree

# Stages are run in order of list. Each stage must be a hash with unique name,
# each stage has four params: vars, command, params and dir.
# Result is like:
# cd $dir && $vars $command $params;
# Some stages have default values for dir/command:
# preconfigure: dir: src
# configure: command: $PACKAGE_SRCDIR/configure
# make: command: make
# install: command: make install
#
# dir is either 'src', or 'build'. Any other values will be used literally.
# 'build' is default for any stage.
#
# Each stage is run separately, was it run or not is stored in status file.
# Also logs/$name.log and logs/$name.sh are created.

# Command line arguments:
# -d,--directory "package directory" (default - current directory)
# -c,--config "config file" (default - config.yaml in package directory, if relative - it will be relative
#                   to package directory)
# -u,--update checks for newer version, if available, runs "clean" and builds (if no new version available, does nothing)
# -l,--clean cLean everything for target (if no target cleans all targets but not downloads)
# -f,--fullclean delete all files produced by package.pl (all targets and downloads, status.yaml)
# -t,--target "target" - build traget (or clean only this target if -l given)
# -s,--sources "dir" - directory with all source archives

# If anything is changed in 'download' section, fullclean is called
# If anything is changed in some target configuration, 'clean' is called for that target before it is built

use Term::ANSIColor;
use YAML::XS;
use Data::Dumper;
use strict;
use warnings;
use Cwd;

use Getopt::Long qw( :config posix_default bundling no_ignore_case );

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


my $packagedir = '';
my $configfile = '';
my $update = '';
my $clean = '';
my $fullclean = '';
my $target = '';
my $prefix = '';
my $packageDownloadDir = '';
my $statusFilename = 'status.yaml';
GetOptions(
    'directory|d=s' => \$packagedir,
    'config|c=s' => \$configfile,
    'update|u' => \$update,
    'clean|l' => \$clean,
    'fullclean|f' => \$fullclean,
    'target|t=s' => \$target,
    'prefix|p=s' => \$prefix,
    'sources|s=s' => \$packageDownloadDir,
    'statusfilename=s' => \$statusFilename
) or die("usage\n");


if (!(-d $packageDownloadDir)) {
    error("No sources directory provided: '$packageDownloadDir'");
}
if (!(-d $prefix)) {
    error("Prefix directory doesn't exist: '$prefix'");
}
if (!$packagedir) {
    $packagedir = getcwd();
}
if (!(-d $packagedir)) {
    error("Package dir '$packagedir' should be directory");
}
die "Can't cd to $packagedir\n" unless chdir $packagedir;
my $status = undef;
my $statusPath =  "$packagedir/$statusFilename";
if (-f $statusPath) {
    $status = YAML::XS::LoadFile("$packagedir/$statusFilename");
} else {
    $status = YAML::XS::Load('');
}
if (!$configfile) {
    if (exists($status->{'configfile'})) {
        $configfile = $status->{'configfile'};
    } else {
        $configfile = "$packagedir/config.yaml";
    }
}

sub fullclean {
    system("rm -rf $statusPath $packagedir/download $packagedir/source $packagedir/targets") == 0
       or error("Couldn't full clean");
    $status = YAML::XS::Load('');
}
sub clean {
    my $target = shift(@_);
    my $status2;
    if ($target) {
        system("rm -rf $packagedir/targets/$target") == 0
            or error("Couldn't clean target $target");
        delete $status->{$target};
        $status2 = $status;
    } else {
        system("rm -rf $packagedir/targets") == 0
            or error("Couldn't clean targets");
        $status2 = {
            'downloaded' => $status->{'downloaded'},
            'downloads' => $status->{'downloads'},
            '_prevconfig' => $status->{'_prevconfig'}
        };
    }
    YAML::XS::DumpFile("$statusPath", $status2);
}
if ($fullclean) {
    $clean = 1;
    fullclean();
    exit(0);
}
if ($clean) {
    print "Cleaning target '$target'\n";
    clean($target);
    exit(0);
}
if (!$target) {
    $target = 'build';
}

my $config = YAML::XS::LoadFile($configfile);
$status->{'configfile'} = $configfile;
YAML::XS::DumpFile("$statusPath", $status);

sub fixRelativeLink { #{{{
    my $absoluteLink = shift(@_);
    my $possiblyRelativeLink = shift(@_);
    my $link = $possiblyRelativeLink;
    if ($possiblyRelativeLink !~ m#^[a-z]+://#) {
        if ($possiblyRelativeLink =~ m#^//#) {
            $absoluteLink =~ s#([a-z]+:).*#\1#;
        } elsif ($possiblyRelativeLink =~ m#^/#) {
            $absoluteLink =~ s#([a-z]+://[^/]+)/.*#\1#;
        } else {
            $absoluteLink =~ s#\?.*$##;
            $absoluteLink =~ s#/[^/]+\.[a-z]+(\?.*)?$#/#;
            if ($absoluteLink !~ m#/$#) {
                $absoluteLink .= '/';
            }
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
    $abs = 'http://thisshouldbe.com/this/should/be/removed.html';
    $rel = '/relative/to/root.html';
    my $expected = 'http://thisshouldbe.com/relative/to/root.html';
    $res = fixRelativeLink($abs, $rel);
    if (!($res eq $expected)) {
        error("Test failed: fixRelativeLink($abs, $rel) = $res, expected: $expected\n");
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
    my $flink =`sed -n "s/^.*href=[\\"']\\([^'\\"]*$package-\\?[0-9.]\\+\\/\\?\\)[\\"'].*\$/\\1/pi" $tmpfile | sort -V | tail -n 1`;
    $flink =~ s/^\s+//;
    $flink =~ s/\s+$//;
    if ($flink eq '') {
        error("Couldn't get version of $package (folder method).\n");
    }
    $flink = fixRelativeLink($link, $flink);
    message("got link: $link, flink: $flink");
    return $flink;
} #}}}
sub getSupportedArchiveFiletypes {
    return ('tar.xz', 'src.tar.xz', 'tar.bz2', 'src.tar.bz2', 'tar.gz', 'src.tar.gz', 'zip');
}
sub getLinkSourceForge { #{{{
#                http://sourceforge.net/api/project/name/tcl/json
#                Get from that link project id, use it to find lates package:
#                http://sourceforge.net/api/file/index/project-id/10894/json
#                Get from this link
#                'http://sourceforge.net/projects/tcl/files/Tcl/8.6.0/tcl-core8.6.0-src.tar.gz/download'
#                -src?..
#                 packagesuffix, versionsuffix
    my $package = shift(@_);
    my $downloaddir = "$packagedir/download";
    system("mkdir -p $downloaddir") == 0
        or error("Couldn't create directory $downloaddir");
    my $tmpfile = "$downloaddir/$package-project-sf";
    my $link = "http://sourceforge.net/api/project/name/$package/json";
    message("Trying to get $link to $tmpfile\n");
    system("wget -O $tmpfile \"$link\"") == 0
        or error("Couldn't download list from '$link' to '$tmpfile' (sourceforge)\n");
    my $id = `sed -n "s/\\"id\\":\\([0-9]\\+\\)/\\1/p" $tmpfile`;
    $id  =~ s/^\s+//;
    $id  =~ s/,\s+$//;
    if (!$id) {
        error("Couldn't get id of sourceforge package!");
    }
    return "http://sourceforge.net/api/file/index/project-id/$id/rss";
} #}}}
sub getVersionWget { #($link, $package, $suffix, $posturl, $prelink, $postlink, $afterpackage) #{{{
    my $params = shift(@_);
    my $link = $params->{'link'};
    my $package = $params->{'package'};
    my $suffix = $params->{'suffix'} // '';
    my $posturl = $params->{'posturl'} // '';
    my $prelink = $params->{'prelink'} // "href=[\\\"']";
    my $postlink = $params->{'postlink'} // "[\\\"']";
    my $versionPattern = $params->{'versionPattern'} // '[-_]\\?[0-9.]\\+';
    my $downloaddir = "$packagedir/download";
    system("mkdir -p $downloaddir") == 0
        or error("Couldn't create directory $downloaddir");
    my $tmpfile = "$downloaddir/$package-list";
    message("Trying to get $link to $tmpfile\n");
    system("wget -O $tmpfile \"$link\"") == 0
        or error("Couldn't download list from '$link' to '$tmpfile'\n");
    my $packageFilename = '';
    my $filetype = '';
    my $downloadLink = '';
    my @filetypes = getSupportedArchiveFiletypes();
    for (@filetypes) {
        #my $filetypesRe = '\(' . join("\\|", @filetypes) . '\)';
        my $filetypesRe = $_;
        #print "sed -n \"s/^.*$prelink\\([^'\\\"]*${package}[-_]\\?[0-9.]\\+$suffix\.$filetypesRe\\)${posturl}$postlink.*\$/\\1/p\" $tmpfile | sort -V | tail -n 1\n";
        $downloadLink =`sed -n "s/^.*$prelink\\([^'\\"]*$package$versionPattern$suffix\.$filetypesRe\\)${posturl}$postlink.*\$/\\1/pi" $tmpfile | sort -V | tail -n 1`;
        if ($downloadLink) {
            last;
        }
    }
    $downloadLink  =~ s/^\s+//;
    $downloadLink  =~ s/\s+$//;
    if ($downloadLink  eq "") {
        error("Couldn't get version of $package.\n");
    }
    $downloadLink = fixRelativeLink($link, $downloadLink);
    $params->{'link'} = $downloadLink;
    return getVersionByLink($params);
} #}}}
sub getVersionByLink {
    my $params = shift(@_);
    my $link = $params->{'link'};
    my $package = $params->{'package'};
    my $suffix = $params->{'suffix'} // '';
    my @filetypes = getSupportedArchiveFiletypes();
    my $filetypesRe = join("|", @filetypes);
    print "filetypesRe: $filetypesRe\n";
    $link =~ /$package([-_]?[0-9.-]*[a-z]?)$suffix\.($filetypesRe)/;
    my $version = $1;
    my $filetype = $2;
    my $packageFilename = "$package$version$suffix.$filetype";

    return ($packageFilename, $filetype, $link, $version);
}
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
sub getMultipleWget { #($name, $link, $re);
    my $name = shift(@_);
    my $link = shift(@_);
    my $re = shift(@_);

    my $downloaddir = "$packagedir/download";
    system("mkdir -p $downloaddir") == 0
        or error("Couldn't create directory $downloaddir");
    my $tmpfile = "$downloaddir/$name-mult-list";
    message("Trying to get $link to $tmpfile\n");
    system("wget -O $tmpfile \"$link\"") == 0
        or error("Couldn't download list from '$link' to '$tmpfile'\n");
    my $filenames = '';

#    print "sed -n \"s/^.*$re.*\$/\\1/p\" $tmpfile | sort -V\n";
    my $downloadLink =`sed -n "s/^.*$re.*\$/\\1/p" $tmpfile | sort -V`;
    my @links = split /\s+/, $downloadLink;
    my @resultList;

    for (@links) {
        /([^\/]*)$/;
        my $filename = $1;
        my $path = "$packageDownloadDir/$filename";
        my $l = fixRelativeLink($link, $_);
        my $h = {
            'filename' => $filename,
            'path' => $path,
            'link' => $l
        };
        push(@resultList, $h);
    }
    return \@resultList;
}

sub exportDownloadVariables {
    foreach my $packagename (keys %{$status->{'downloads'}}) {
        if (exists($status->{'downloads'}{$packagename}{'list'})) {
            my @values = ();
            foreach (@{$status->{'downloads'}{$packagename}{'list'}}) {
                push(@values, "$_->{'path'}");
            }
            $ENV{"\U${packagename}_FILENAMES"} = join(' ', @values);
        } else {
            my $varname = "\U${packagename}_SRC_DIR";
            $ENV{$varname} = $status->{'downloads'}{$packagename}{'srcdir'};
            my $varnamearch = "\U${packagename}_SRC_ARCHIVE";
            $ENV{$varnamearch} = $status->{'downloads'}{$packagename}{'archive'};
            if ($packagename eq $config->{'name'}) {
                $ENV{'PACKAGE_SRCDIR'} = $status->{'downloads'}{$packagename}{'srcdir'};
                $ENV{'PACKAGE_VERSION'} = $status->{'downloads'}{$packagename}{'version'};
            }
        }
    }
}
if ($target ne 'root-before' && $target ne 'root-after') {
    if (!(   ($status->{'_prevconfig'}{'download'} ~~ $config->{'download'})
          && ($config->{'download'} ~~ $status->{'_prevconfig'}{'download'})
          )
       )
    {
        message("Something changed in download configuration - making fullclean.");
        fullclean();
        $status->{'_prevconfig'}{'download'} = $config->{'download'};
        YAML::XS::DumpFile("$statusPath", $status);
    }
    if (!exists $status->{'downloaded'} || $update) {
        my $somethingnew = 0;
        my $packagename = $config->{'name'};
        foreach (@{$config->{'download'}}) {
            my $name = $_->{'name'} // $packagename;
            my $link = $_->{'link'};
            if (ref($link)) {
                if (!$link->{'eval'}) {
                    error ("Link can be hash with eval key or string.");
                }
                $link = eval($link->{'eval'});
            }
            my $method = $_->{'method'} // 'wget';
            my $suffix = $_->{'suffix'} // '';
            my $posturl = '';
            my $archivename = undef;
            my $filetype = undef;
            my $srcdir = undef;
            my $version = undef;
            my $wgetParams = {
                'link' => $link,
                'package' => $name,
                'suffix' => ($_->{'suffix'} // '')
            };
            if (exists($_->{'versionPattern'})) {
                $wgetParams->{'versionPattern'} = $_->{'versionPattern'};
            }
            if (exists($status->{'downloads'}{$name}{'downloaded'}) && ($status->{'downloads'}{$name}{'downloaded'} eq '1') && !$update) {
                next;
            }

            if ($method eq 'wget-folder') {
                if (!$link) {
                    error("No link provided for download of $name (wget-folder)");
                }
                my $n = $_->{'wget-folder-name'} // $name;
                $wgetParams->{'link'} = getLinkFolderWget($link, $n);
                if (!$wgetParams->{'link'}) {
                    error("Couldn't get last version from folder $link, $name");
                }
                message("Latest version link: $link");
                $method = 'wget';
            }
            if ($method eq 'sourceforge') {
                $wgetParams->{'link'} = getLinkSourceForge($name);
                if (!$wgetParams->{'link'}) {
                    error("Couldn't get last version from sourceforge $link, $name");
                }
                $wgetParams->{'posturl'} = '\\/download';
                $wgetParams->{'prelink'} = '<link>';
                $wgetParams->{'postlink'} = '<\\/link>';
                $method = 'wget';
            }
            if ($method eq 'wget' || $method eq 'fixed') {
                if (!$wgetParams->{'link'}) {
                    error("No link provided for download of $name (wget)");
                }
                my $packageFilename;
                if ($method eq 'wget') {
                    ($packageFilename, $filetype, $link, $version) = getVersionWget($wgetParams);
                } elsif($method eq 'fixed') {
                    ($packageFilename, $filetype, $link, $version) = getVersionByLink($wgetParams);
                }
                if (!$packageFilename) {
                    error("Error getting version of $name by link $link.");
                }
                if (!exists($status->{'downloads'}{$name}{'version'}) || !($version eq $status->{'downloads'}{$name}{'version'})) {
                    $somethingnew = 1;
                } else {
                    message("No new version for $name. Last version: $version");
                    next;
                }
                $archivename = "$packageDownloadDir/$packageFilename";
                if (not -f$archivename) {
                    system("wget \"$link\" -c -O \"$archivename\"") == 0
                        or error("Couldn't download $link (package: $name).\n");
                }
                $srcdir = "$packagedir/source";
                status("Downloaded $archivename");
                extract($archivename, $filetype, $srcdir);
                status("Extracted $archivename");
                $status->{'downloads'}{$name}{'srcdir'} = "$srcdir/$name$version";
                $status->{'downloads'}{$name}{'version'} = $version;
                $status->{'downloads'}{$name}{'archive'} = $archivename;
                $status->{'downloads'}{$name}{'filetype'} = $filetype;
                $status->{'downloads'}{$name}{'downloaded'} = '1';
            } elsif ($method eq 'wget-multiple') {
                my $re = $_->{'re'};
                my $list = getMultipleWget($name, $link, $re);
                if (!exists($status->{'downloads'}{$name}{'list'}) || !($list ~~ $status->{'downloads'}{$name}{'list'} && $status->{'downloads'}{$name}{'list'})) {
                    $somethingnew = 1;
                } else {
                    message("No new files for $name.");
                }
                for (@{$list}) {
                    system("wget \"$_->{'link'}\" -c -O \"$_->{'path'}\"") == 0
                        or error("Couldn't download $_->{'link'} to $_->{'path'} (multiple: $name).\n");
                }
                $status->{'downloads'}{$name}{'downloaded'} = '1';
                $status->{'downloads'}{$name}{'list'} = $list;
                status("Downloaded multiple $name");
            } else {
                error("Unsupported download method '$method'");
            }
            YAML::XS::DumpFile("$statusPath", $status);
        }
        $status->{'downloaded'} = 1;
        YAML::XS::DumpFile("$statusPath", $status);
        if ($somethingnew) {
            status("Downloaded $packagename successfully\n");
            clean();
        } elsif($update) {
            status("Nothing new, everything is up to date");
            exit(0);
        }
    }
    exportDownloadVariables();
}
$ENV{'PREFIX'} = $prefix;

my $stageDefaultParams = {
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
    'make' => {
        'command' => 'make'
    },
    'test' => {
        'command' => 'make test'
    },
    'install' => {
        'command' => 'make install'
    },
    'check' => {
        'command' => 'make check'
    },
};

sub processStage {
    my $name = shift(@_);
    my $conf = shift(@_);

    if ($status->{$target}{$name}) {
        message("Phase $name is already done");
        return;
    }
    my $command = '';

    my @params = ('dir', 'vars', 'command', 'params');
    my %paramValues = ();
    for (@params) {
        if (ref($conf) && exists($conf->{$_})) {
            $paramValues{$_} = $conf->{$_};
        } elsif (exists($stageDefaultParams->{$name}{$_})) {
            $paramValues{$_} = $stageDefaultParams->{$name}{$_};
        } else {
            $paramValues{$_} = '';
        }
    }
    if ($paramValues{'dir'} eq '') {
        $paramValues{'dir'} = 'build';
    }

    message("Running phase $name");

    my $srcdir = $status->{'downloads'}{$config->{'name'}}{'srcdir'};
    my $builddir = "$packagedir/targets/$target";
    my $logdir = "$packagedir/targets/$target-logs";
    my $logfile = "$logdir/$name.log";
    system("mkdir -p $logdir") == 0
        or error("Couldn't create directory $logdir");

    my $dir = '';
    if ($paramValues{'dir'} eq 'src') {
        $dir = $srcdir;
    } elsif ($paramValues{'dir'} eq 'build') {
        $dir = $builddir;
        system("mkdir -p $builddir") == 0
            or error("Couldn't create directory $builddir");
    }
    chdir($dir);
    $command = "$paramValues{'vars'} $paramValues{'command'} $paramValues{'params'}";
    if (!ref($conf) && $conf) {
        $command .= " $conf";
    }

    my $scriptfile = "$logdir/$name.sh";
    open(SCRIPT, '>', $scriptfile)
        or error("Couldn't create $scriptfile\n");
    print SCRIPT "#!/bin/bash\n";
    print SCRIPT "set -e\n";
    print SCRIPT "{ time {\n";
    print SCRIPT "$command\n";
    print SCRIPT "}; } 2>&1 | tee $logfile\n";
    print SCRIPT "exit \${PIPESTATUS[0]}\n";
    close SCRIPT;
    system("chmod +x $scriptfile") == 0
        or error("Couldn't make '$scriptfile' executable");

    system("$scriptfile") == 0
        or error("Failure running $name phase");

    status("Phase $name is done");
    $status->{$target}{$name} = '1';
    YAML::XS::DumpFile("$statusPath", $status);
}

if (!(   ($status->{'_prevconfig'}{$target} ~~ $config->{$target})
      && ($config->{$target} ~~ $status->{'_prevconfig'}{$target})
   ))
{
    message("Something changed in '$target' configuration - making clean.");
    clean($target);
    $status->{'_prevconfig'}{$target} = $config->{$target};
    YAML::XS::DumpFile("$statusPath", $status);
}
foreach (@{$config->{$target}}) {
    my $key;
    my $value;
    while (($key, $value) = each %{$_}) {
        processStage($key, $value);
    }
}
