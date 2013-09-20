#!/usr/bin/perl
use warnings;
use strict;
use POSIX;
use File::Path qw(make_path);

##############################################################################
# Author: Dan Shea
# Date: 2013-09-20
# Description:
# This script creates a user specified number of files of a size specified by
# the user in 1kB blocks.  The total number of files is passed as an argument
# and the script attempts to determine an optimal number directories to create
# based on the total number of files requested.  For example, if you specify
# that you want 100,000 1kB files, it will split them up into 100 directories
# each consisting of 1000 1kB files.  This behaviour may be changed by editing
# the $files_per_directory variable.
#
# Usage:
#      ./chunk_factory.pl <target_directory> <number_of_files> <size_of_files>
#
# Note:
#      target_directory: The directory to create the subdirectories full of
#                        files.
#      number_of_files:  The total number of files you wish to create.
#      size_of_files:    The size that each file should be, in 1kB blocks.
#
# Example:
#      ./chunk_factory.pl /mnt/mfs 10000 1
#
# This will create 10,000 files of size 1kB each, splitting them across 10
# subdirectories.
#
##############################################################################

# Determines the number of files to place within a single directory
my $files_per_directory = 2;

sub usage {
    print STDERR "$0 <target_directory> <number_of_files> <size_of_files>\n\n";
    print STDERR "Where:\n";
    print STDERR "target_directory: The directory to create the subdirectories full of files.\n";
    print STDERR "number_of_files:  The total number of files you wish to create.\n";
    print STDERR "size_of_files:    The size that each file should be, in 1kB blocks.\n";
    exit(1);
}


# First, check to ensure the proper number of arguments has been passed into
# the script
my $number_of_arguments = @ARGV;
if ($number_of_arguments != 3) {
    &usage;
}

# We have 3 arguments, let's evaluate them for correctness
(my $target_directory, my $number_of_files, my $size_of_files) = @ARGV;

# Does the target directory exist and can we write to it?
unless (-d $target_directory) {
    print STDERR "$target_directory does not exist.\n";
    exit(1);
}
unless (-w $target_directory) {
    print STDERR "$target_directory is not writable.\n";
    exit(1);
}

# Is the number of files a positive integer value?
unless ($number_of_files =~ /^[0-9]+$/) {
    print STDERR "The number_of_files must be a positive integer value.\n";
    exit(1);
}

# Is the size of files a positive integer value?
unless ($size_of_files =~ /^[0-9]+$/) {
    print STDERR "The size_of_files must be a positive integer value.\n";
    exit(1);
}

# OK, it looks like we have valid arguments, let's evaluate the type of
# directory structre we must now create.  Each directory can not contain more
# than $files_per_directory files.  Therefore, we must calculate the number of
# directories we will need to create the filesystem.

# First, let's determine how many directories in total we will need to store all
# of the files.

my $total_number_of_directories = ceil($number_of_files / $files_per_directory);

# OK, now we need to break this down into a tree so we never have more than
# $files_per_directory directories in any one directory.  We can determine this
# by noticing that log base $files_per_directory of the $total_number_of_directories
# tells us how many levels of directories we're going to need.
# Recall that log base n divided by log base n of the base we actually want gives
# us the right answer.  Take the ceiling of that to determine the number of subdirectory
# levels we will need to distribute the files through the directory hierarchy.

my $number_of_levels = ceil(log($total_number_of_directories) / log($files_per_directory));

# Alright, now we can create the directory hierarchy and place the files at the lowest
# level of the tree (Note: this give us a slightly deeper tree structure in some cases since
# we won't always make use of all of the leaves in the tree)

chdir($target_directory);
my @directory_stack = ($target_directory);
my $directories_created = 0;
my $files_created = 0;
my $current_level = 0;
my $go_up = 0;

do {
    my $current_directory = shift(@directory_stack);
    chdir($current_directory);
    $current_level++;
    # We can construct the paths and then use the File::Path make_path subroutine
    # to create the directories we need as we go
    for my $j (1..$files_per_directory){
        if ($current_level < $number_of_levels) {
            make_path($j);
            unshift(@directory_stack, $j);
            $directories_created++;
        }
        else {
            qx(dd if=/dev/zero of=$j bs=1024k count=$size_of_files);
            $files_created++;
            $go_up = 1;
        }
    }
    if ($go_up) {
        chdir("..");
        $current_level--;
    }
} while ($files_created < $number_of_files);