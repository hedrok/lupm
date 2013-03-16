#!/usr/bin/perl
$SUDO = $ENV{SUDO};
$partition = $ARGV[0];
%allowed = (
    'has_journal' => 1,
    'ext_attr' => 1,
    'resize_inode' => 1,
    'dir_index' => 1,
    'filetype' => 1,
    'sparse_super' => 1,
    'large_file' => 1,
    'needs_recovery' => 1
);
$result = `$SUDO debugfs -R feature $partition`;
@result = split(':', $result);
$result = $result[1];
if ($result eq '') {
    print "debugfs failed! Can't determine extra functions of ext3 (partition $partition)\n";
    exit 1;
}
for (split(' ', $result)) {
    if (! exists($allowed{$_})) {
        print "Extra function: $_, you need to rebuild e2fsprogs and reformat partition!\n";
        exit 1;
    }
}
