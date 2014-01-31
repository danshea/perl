#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use feature qw(say);

=cut
Name: testInstalledVersion.pl
Author: Dan Shea
Date: 2014-01-31
Description: Command run by unless clause in moose-client module to determine
if we need to install the supplied Debian Packages.
Exit code 0 == success, no need to install anything
Exit code 1 == failure, need to install updated package
=cut


# GLOBALS
my $PACKAGE_NAME = '';
my $VERSION_NUM = '';
my $USAGE = "\n$0 [options]\n\n
Options:
-package    The name of the package to query
-version    The version to test for
-help       Display this message
\n";

GetOptions(
    'package=s' =>  \$PACKAGE_NAME,
    'version=s' =>  \$VERSION_NUM,
    'help'      =>  sub {pod2usage($USAGE);},
           ) or pod2usage(2);

sub ltrim { my $s = shift; $s =~ s/^\s+//; return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//; return $s };
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub queryPackage{
    my $output = qx/dpkg -s $PACKAGE_NAME 2>&1/;
    my $return_code = $?;
    unless ($output =~ /Version: .*?\n/){
        say "Couldn't retrieve version information for $PACKAGE_NAME";
        exit(1);
    }
    else{
        my $installed_version = $output =~ /Version: (.*?)\n/ ? $1 : '';
        chomp($installed_version);
	$installed_version = trim($installed_version);
        if ($installed_version ne $VERSION_NUM) {
            say "changed=true comment=\"Query version is: $VERSION_NUM Installed version is: $installed_version Performing upgrade.\"";
            exit(0);
        }
        else{
            say "changed=false comment=\"Query version is: $VERSION_NUM Installed version is: $installed_version Performing no action.\"";
            exit(1);
        }
    }
}

unless($PACKAGE_NAME){
    pod2usage($USAGE);
}
unless($VERSION_NUM){
    pod2usage($USAGE);
}

queryPackage();
