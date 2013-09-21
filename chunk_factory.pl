#!/usr/bin/perl
use warnings;
use strict;
use POSIX;
use File::Path qw(make_path);
use Cwd;

##############################################################################
# Author: Dan Shea
# Date: 2013-09-20
# Description:
#
# Usage:
#      ./chunk_factory.pl <target_directory> <number_of_files> <files_per_directory> <size_of_files>
#
# Note:
#      target_directory:    The directory to create the subdirectories full of
#                           files.   
#      number_of_files:     The total number of files you wish to create.
#      files_per_directory: The max number of files in each directory.\n"
#      size_of_files:       The size that each file should be, in 1kB blocks.
#
# Example:
#      ./chunk_factory.pl /mnt/mfs 10000 1000 1
#
# This will create 10,000 files of size 1kB each, splitting them across 10
# subdirectories.
#
##############################################################################

# Usage subroutine
sub usage {
    print STDERR "$0 <target_directory> <number_of_files> <files_per_directory> <size_of_files>\n\n";
    print STDERR "Where:\n";
    print STDERR "target_directory: The directory to create the subdirectories full of files.\n";
    print STDERR "number_of_files:  The total number of files you wish to create.\n";
    print STDERR "files_per_directory: The max number of files in each directory.\n";
    print STDERR "size_of_files:    The size that each file should be, in 1kB blocks.\n";
    exit(1);
}

# First, check to ensure the proper number of arguments has been passed into
# the script
my $number_of_arguments = @ARGV;
if ($number_of_arguments != 4) {
    &usage;
}

# We have 4 arguments, let's evaluate them for correctness
(my $target_directory, my $number_of_files, my $files_per_directory, my $size_of_files) = @ARGV;

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

# Is the number of files per directory a positive integer value?
unless ($files_per_directory =~ /^[0-9]+$/) {
    print STDERR "The files_per_directory must be a positive integer value.\n";
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
# level of the tree
my $files_created = 0;
my $directories_created = 0;
my $current_level = 0;
my @dirstack = ();
my $directory;

# Prime the stack
chdir($target_directory);
print "cwd is now $target_directory\n";
unshift(@dirstack, $target_directory);

while (@dirstack and $files_created < $number_of_files) {
    
    if ($current_level == $number_of_levels) {
        my $file_count = 0;
        while ($files_created < $number_of_files and $file_count < $files_per_directory){
            my $filename = $files_created.".dat";
            qx(dd if=/dev/zero of=$filename bs=1k count=$size_of_files);
            $files_created++;
            $file_count++;
        }
        # Go up a directory
        $directory = shift(@dirstack);
        chdir("..");
        print "cwd is now $directory\n";
        $current_level--;
    }
    # How many directories are at this level?  If we've already created the max, go up a directory
    my @listing = qx(ls);
    my $count = @listing;
    if ($count == $files_per_directory) {
        $directory = shift(@dirstack);
        chdir("..");
        print "cwd is now $directory\n";
        $current_level--;
    }
    # Otherwise create a directory and cd into it
    else {
        my $dirname = $directories_created.".dir";
        make_path($dirname);
        $directories_created++;
        chdir($dirname);
        unshift(@dirstack, $dirname);
        $current_level++;
        print "cwd is now $dirname\n";
    }
}