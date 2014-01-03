#!/usr/bin/perl

#our command: 
#useradd -b /usr/src -c 'comment' -g group -G instgroup1,instgroup2,instgroup3 -k skeldir username

#0 success
#1 can't update password file
#2 invalid command syntax
#3 invalid argument to option
#4 UID already in use (and no -o)
#6 specified group doesn't exist
#9 username already in use
#10 can't update group file
#12 can't create home directory
#13 can't create mail spool

use Getopt::Long qw( :config posix_default bundling no_ignore_case );

my $basedir = '';
my $comment = '';
my $group = '';
my $othergroups = '';
my $skeldir = '';
GetOptions(
    'base-dir|b=s' => \$basedir,
    'comment|c=s' => \$comment,
    'gid|g=s' => \$group,
    'groups|G' => \$otherGroups,
    'skel|k' => \$skeldir,
) or exit 2;

if ($basedir eq '' || $group eq '' || $skeldir eq '') {
    exit 2;
}

my $optionsnum = @ARGV;
if ($optionsnum != 1) {
    exit 2;
}
my $minuid = 1000;
my $username = $ARGV[0];
print "argv: @ARGV";

$maingid = getGroupId $group;

my $lastline = '';
open (USERREAD, "</etc/passwd") or exit 10;
while (<USERREAD>)
{
    if (/^$username:/) {
        exit 9;
    }
    $lastline = $_; 
}
close (USERREAD);
$lastline =~ /^[^:]*:[^:]*:([0-9]+):/;
my $lastid = $1;
print "got last uid: $lastid\n";
my $uid = $lastid + 1;
if ($uid < $minuid) {
    $uid = $minuid;
}
system("echo '$username:x:$uid:$maingid:$comment:$basedir/$username:/bin/bash' >> /etc/passwd") == 0
    or exit 10;

exit 0;

#ubuntu:x:999:999:Live session user,,,:/home/ubuntu:/bin/bash
