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
my $link;
my $md5;
my $maxAttempts = 100;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "link=s"            => \$link,
            "md5=s"             => \$md5,
	    "maxAttempts=i"     => \$maxAttempts
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my $attempts = 1;

##############################
# Code
##############################


##############################
### Stuff
### More stuff

while (1) {
    my $fileName = $link;
    $fileName =~ s/.+\///;
    print $fileName, " attempt number ", $attempts, "\n";

    my $return = system("wget -c -t 1 " . $link);

    if ($return == 0) {
        if ($md5) {
            my $cmpMd5Cmd = "md5sum " . $fileName;
            my $cmpMd5 = `$cmpMd5Cmd`;
            $cmpMd5 =~ s/ .+\n//;
            if ($cmpMd5 eq $md5) {
                print STDERR "File downloaded and md5sum is correct.\n";
                print STDERR "Success after only $attempts attempts!\n";
                last;
            } else {
                print STDERR "Calculated md5 incorrect: " . $cmpMd5, "\n";
                print STDERR "Deleting file and retrying download\n";
                system("rm $fileName");
                sleep(5);
            }
        } else {
            print STDERR "File downloaded. No md5 check performed.\n";
            print STDERR "Success after only $attempts attempts!\n";
            last;
        }
    }
    $attempts++;

    if ($attempts > $maxAttempts) {
	last;
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
