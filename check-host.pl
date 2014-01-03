#!/usr/bin/perl
sub getVersion {
    my $input = shift(@_);
    if ($input =~ /\b[0-9]+\.[0-9.a-b-]+\b/p) {
        return(${^MATCH});
    }
}
sub checkVersion {
    my $program = shift(@_);
    my $minVersion = shift(@_);
    my $extra = shift(@_);
    if ($extra eq '') {
        $extra = '--version';
    }
    my $package = shift(@_);
    if ($package eq '') {
        $package = $program;
    }
    my $out = `$program $extra`;
    my $version = getVersion($out);
    if ($version == undef) {
        print "command '$program' not found\n";
        return 1;
    }
    my @versionArray = split("\\.", "$version");
    my @minVersionArray = split("\\.", $minVersion);
    my $n1 = @versionArray;
    my $n2 = @minVersionArray;
    my $n = $n1;
    if ($n2 < $n) { 
        $n = $n2;
    }
    for ($i = 0; $i < $n; $i++) {
        if ($versionArray[$i] > $minVersionArray[$i]) {
            print "Version of '$package' is OK: $version, required: $minVersion\n";
            return 0;
        }
        if ($versionArray[$i] < $minVersionArray[$i]) {
            print "Version of '$package' is too old: $version, required: $minVersion\n";
            return 2;
        }
    }
    if ($n1 < $n2) {
        print "Version of '$package' is too old: $version, required: $minVersion\n";
        return 2;
    }
    print "Version of '$package' is OK: $version, required: $minVersion\n";
    return 0;
}
#Bash-3.2 (/bin/sh should be a symbolic or hard link to bash)
if (checkVersion("bash", "3.2")) {
    exit 1;
}
if (`readlink -f /bin/sh` != '/bin/bash') {
    print "/bin/sh is not link to /bin/bash!";
    exit 1;
}
if (checkVersion("ld", "2.17")) {
    print "Update binutils!\n";
    exit 1;
}
#Bison-2.3 (/usr/bin/yacc should be a link to bison or small script that executes bison)
if (checkVersion("bison", "2.3")) {
    exit 1;
}
if (`readlink -f /usr/bin/yacc/` != "/usr/bin/bison") {
    print "/usr/bin/yacc is not link to /usr/bin/bison!";
    exit 1;
}
if (checkVersion("bzip2", "1.0.4", "--version 2>&1") || checkVersion("chown", "6.9")
    || checkVersion('diff', '2.8.1')
    || checkVersion('gawk', '3.1.5'))
{
    exit 1;
}
if ( `readlink -f /usr/bin/awk` != '/usr/bin/gawk' ) {
    print "/usr/bin/awk is not link to /usr/bin/gawk!";
    exit 1;
}

if (   checkVersion('g++', '4.7.2')
    || checkVersion('ldd', '2.5.1')
    || checkVersion('grep', '2.5.1a')
    || checkVersion('gzip', '1.3.12')
    || checkVersion('m4', '1.4.10')
    || checkVersion('make', '3.81')
    || checkVersion('patch', '2.5.4')
    || checkVersion('perl', '5.8.8')
    || checkVersion('sed', '4.1.5')
    || checkVersion('tar', '1.18')
    || checkVersion('makeinfo', '4.9', '', 'Tex Info')
    || checkVersion('xz', '5.0.0')
    || checkVersion('cat', '2.6.25', '/proc/version', 'Linux Kernel')
   )
{
    exit 1;
}

#testing gcc compilation
system("echo 'main(){}' > dummy.c && gcc -o dummy dummy.c");
if ( -x 'dummy' ) {
  print "gcc compilation OK\n";
  system("rm -f dummy.c dummy");
} else {
  print "gcc compilation failed\n";
  system("rm -f dummy.c dummy");
  exit 1;
}
