#!/usr/bin/perl

# Supports no options, only group name
# groupadd install
#
# Returns  2 if extra options/no group name
# Returns  9 if group already exists, 0 on success.
# Returns 10 if can't access /etc/group

my $mingid = 1000;
my $optionsnum = @ARGV;
if ($optionsnum != 1) {
    exit 2;
}
my $group = $ARGV[0];

my $lastline = '';
open (GROUPREAD, "</etc/group") or exit 10;
while (<GROUPREAD>)
{
    if (/^$group:/) {
        exit 9;
    }
    $lastline = $_; 
}
close (GROUPREAD);
$lastline =~ /^[^:]*:[^:]*:([0-9]+):/;
my $lastid = $1;
print "got last gid: $lastid\n";
my $gid = $lastid + 1;
if ($gid < $mingid) {
    $gid = $mingid;
}
system("echo '$group:x:$gid:' >> /etc/group") == 0
    or exit 10;

exit 0;
