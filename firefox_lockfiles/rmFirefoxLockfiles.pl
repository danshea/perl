#!/usr/bin/env perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use File::Spec;
use File::HomeDir;

###############################################################################
#
# Name: rmFirefoxLockfiles.pl
# Date: 2014-02-07
# Author: Dan Shea
# Description:
#
#   When firefox starts, it checks for the existence of lockfiles in the
#   invoking user's $HOME/.mozilla
#
#   This script will attempt to find any running firefox browser processes
#   kill them if necessary and clean up the lockfiles if they exist.
#
###############################################################################

# GLOBALS
my $whoami_exec = qx/which whoami/;
chomp($whoami_exec);
my $whoami = qx/$whoami_exec/;
chomp($whoami);
my $home = File::HomeDir->my_home();
my $grep_exec = qx/which grep/;
chomp($grep_exec);
my $ps_exec = qx/which ps/;
chomp($ps_exec);
my $awk_exec = qx/which awk/;
chomp($awk_exec);
=cut
my $USER = '';
my $HOME_DIR = '';

my $usage = "\nUSAGE:\n
$0 [options]\n
Options:\n
-user   The user to use, this defaults to the invoking user if no argument is given.
-help   Display this message.\n";

GetOptions(
    'user=s' =>  \$USER,
    'help'  =>  sub{pod2usage($usage);},
           ) or pod2usage(2);
=cut

# SUBROUTINES
sub ltrim { my $s = shift; $s =~ s/^\s+//; return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//; return $s };
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

# Find any running firefox processes and return their pids or NULL if none found.
sub findFirefoxen{
    my $results = qx/$ps_exec auxwww | $grep_exec $whoami | $grep_exec firefox | $grep_exec -v grep | $awk_exec '{print \$2}'/;
    return(split(/\s+/, $results));
}

# Take a list of pids to kill as argument and kill these pids.
sub killFirefoxen{
    my @pids = @_;
    my $kill_exec = qx/which kill/;
    chomp($kill_exec);
    foreach my $pid (@pids){
        qx/kill $pid/;
    }
}

# Find any firefox lockfiles in the user's $HOME/.mozilla directory, return as a list
# or return NULL if none are found.
sub findLockfiles{
    # Remove $HOME/.mozilla/firefox/lock and $HOME/.mozilla/firefox/.parentlock
    my $lockfiledir = File::Spec->catdir(($home, '.mozilla', 'firefox'));
    my $defaultdir = qx/ls -ld $lockfiledir\/*.default | $awk_exec '{print \$8}'/;
    chomp($defaultdir);
    $lockfiledir = File::Spec->catdir(($lockfiledir, $defaultdir));
    my $lockfile = File::Spec->catfile(($lockfiledir),'lock');
    my $parentlockfile = File::Spec->catfile(($lockfiledir),'.parentlock');
    return(($lockfile, $parentlockfile));
}

# Take a list of lockfiles to remove and remove them.
sub removeLockfiles{
    my @lockfiles = @_;
    foreach my $lockfile (@lockfiles){
        if (-f $lockfile) {
            qx/rm $lockfile/;
        }
    }
}

# MAIN
=cut
unless($USER){
    $USER = $whoami;
    $HOME_DIR = File::HomeDir->users_home($USER);
}
=cut
say "Using username: $whoami";
say "Using \$HOME: $home";
my @pids = findFirefoxen();
say "Killing @pids";
=cut
killFirefoxen();
=cut
my @lockfiles = findLockfiles();
say "Removing @lockfiles";
=cut
removeLockfiles();
=cut
say "Lock files have been removed, please try to re-start firefox.";
exit(0);