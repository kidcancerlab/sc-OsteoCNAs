#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;


##############################
# By Matt Cannon
# Date: 
# Last modified: 
# Title: .pl
# Purpose: 
##############################

##############################
# Options
##############################


my $verbose;
my $help;
my $linkFile;
my $md5File;
my $debug;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "linkFile=s"        => \$linkFile,
            "md5File=s"         => \$md5File,
            "debug"             => \$debug
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my %linkHash;

##############################
# Code
##############################


##############################
### Stuff
### More stuff

open my $linkFileFH, "$linkFile" or die "Could not open link file\n.$!";
while (my $input = <$linkFileFH>){
    chomp $input;
    my $file = $input;
    $file =~ s/.+\///;
    print STDERR $file, " link\n" if ($debug);
    $linkHash{$file} = $input;
}

##############################
### Stuff
### More stuff

open my $md5FileFH, "$md5File" or die "Could not open md5 file\n.$!";
while (my $input = <$md5FileFH>){
    chomp $input;
    my ($md5, $file) = split " ", $input;
    $file =~ s/.+\///;
    print STDERR $file, " md5\n" if ($debug);
    if (exists($linkHash{$file})) {
      print $linkHash{$file}, " ", $md5, "\n";
    } else {
      print STDERR $file, " not found\n" if ($debug);
    }
}


##############################
# POD
##############################

#=pod
    
=head SYNOPSIS

Summary:    
    
    xxxxxx.pl - 
    
Usage:

    perl xxxxxx.pl [options] 


=head OPTIONS

Options:

    --verbose
    --help

=cut
