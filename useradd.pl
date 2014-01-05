#!/usr/bin/perl

#our command: 
#useradd -b /usr/src -c 'comment' -g group -G instgroup1,instgroup2,instgroup3 username

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

sub getGroupId {
    my $group = shift(@_);

    my $lastline = '';
    open (GROUPREAD, "</etc/group")
        or exit 10;
    while (<GROUPREAD>)
    {
        if (/^$group:/) {
            $_ =~ /[^:]+:x:([0-9]+)/;
            close (GROUPREAD);
            return $1;
        }
    }
    close (GROUPREAD);
    return 0;
}
sub addUserToGroup {
    my $id = shift(@_);
    my $user = shift(@_);

    my $lastline = '';
    open (GROUPREAD, "</etc/group")
        or exit 10;
    while (<GROUPREAD>)
    {
        if (/^[^:]+:x:$id:/) {
            close (GROUPREAD);
            if (/:$/) {
                print "sed -i 's/^\\([^:]\\+:x:$id:\\)/\\1$user/' /etc/group\n";
                system("sed -i 's/^\\([^:]\\+:x:$id:\\)/\\1$user/' /etc/group") == 0
                    or die("add user $user to group $id failed (:)")
            } else {
                print "sed -i 's/^\\([^:]\\+:x:$id:.*\\)/\\1,$user/' /etc/group\n";
                system("sed -i 's/^\\([^:]\\+:x:$id:.*\\)/\\1,$user/' /etc/group") == 0
                    or die("add user $user to group $id failed (,)")
            }
            return 1
        }
    }
    close (GROUPREAD);
    return 0;
}

use Getopt::Long qw( :config posix_default bundling no_ignore_case );

my $basedir = '';
my $comment = '';
my $group = '';
my $othergroups = '';
#my $skeldir = '';
GetOptions(
    'base-dir|b=s' => \$basedir,
    'comment|c=s' => \$comment,
    'gid|g=s' => \$group,
    'groups|G=s' => \$othergroups,
#'skel|k' => \$skeldir,
) or exit 2;

#|| $skeldir eq ''
if ($basedir eq '' || $group eq '') {
    exit 2;
}
my $optionsnum = @ARGV;
if ($optionsnum != 1) {
    exit 2;
}
my $minuid = 1000;
my $username = $ARGV[0];

system("groupadd $group");
if ($? == -1) {
}
if (($? & 127) != 0 && ($? & 127) != 9) {
    print "Returned: " . ($? & 127) . "\n";
    exit 10;
}

$maingid = getGroupId($group);
if ($maingid == 0) {
    print "got maingid == 0\n";
    exit 10;
}

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
my $uid = $lastid + 1;
if ($uid < $minuid) {
    $uid = $minuid;
}
my @grouplist = split(',', $othergroups);
my @groupids;
for (@grouplist) {
    my $i = getGroupId($_);
    if ($i == 0) {
        print "Group $_ does not exist\n";
        exit 10;
    }
    push(@groupids, $i)
}
system("echo '$username:x:$uid:$maingid:$comment:$basedir/$username:/bin/bash' >> /etc/passwd") == 0
    or exit 10;

for (@groupids) {
    addUserToGroup($_, $username);
}

exit 0;

#ubuntu:x:999:999:Live session user,,,:/home/ubuntu:/bin/bash
