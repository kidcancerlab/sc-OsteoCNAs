#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;

##############################
# By Matt Cannon
# Date: 
# Last modified: 
# Title: varscanToMatrix_parallel.pl
# Purpose: 
##############################

##############################
# Options
##############################
my $verbose;
my $help;
my $debug;
my $fileList;
my $windowSize = 10000;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "debug"             => \$debug,
            "fileList=s"        => \$fileList,
            "windowSize=i"      => \$windowSize
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my %resultsHash;
my %sampleHash;
my %distHash;

##############################
# Code
##############################

my $files = `ls $fileList`;
chomp $files;
#print STDERR "Files: $files\n";

my @fileArray = split(/\n/, $files);

##############################
### Pull in each output from varscan, break the output up into windows and then add the data to a hash

for my $file (@fileArray) {
    my $sampleName = $file;
    $sampleName =~ s/.+\///;
    $sampleName =~ s/_chr.+//;

    print STDERR $file .  "\n" if ($verbose);

    $sampleHash{$sampleName} = 1;

    open my $inputFH, $file or die "Can't open $file: $!\n";

    while (my $input = <$inputFH>) {
        chomp $input;

        if ($input !~ /^chrom/) {
            my ($chrom, $chr_start, $chr_stop, $num_positions, undef, undef, $adjusted_log_ratio) = split "\t", $input;

            my $window = $chrom . "_" . int($chr_start / $windowSize);
            $resultsHash{$window}{$sampleName}{sum} += 2**$adjusted_log_ratio * $num_positions;
            $resultsHash{$window}{$sampleName}{count} += $num_positions;
        }
    }
}

my @sampleList = keys %sampleHash;

# Calculate distance for each pair of samples
for my $window (keys %resultsHash) {
    for (my $i = 1; $i < scalar(@sampleList); $i++) {
        for (my $j = 0; $j < $i; $j++) {
            if (exists($resultsHash{$window}{$sampleList[$i]}{sum}) &&
                    exists($resultsHash{$window}{$sampleList[$j]}{sum})) {

                my $val_i = $resultsHash{$window}{$sampleList[$i]}{sum} /
                            $resultsHash{$window}{$sampleList[$i]}{count};

                my $val_j = $resultsHash{$window}{$sampleList[$j]}{sum} /
                            $resultsHash{$window}{$sampleList[$j]}{count};

                my $dist = abs($val_i - $val_j);
                #print STDERR $dist, "\n" if ($debug);

                $distHash{$sampleList[$i]}{$sampleList[$j]}{dist} += $dist;
                $distHash{$sampleList[$i]}{$sampleList[$j]}{compared}++;
            }
        }
    }
}

# print out lower-left triangular matrix
print "#mega\nTITLE: Lower-left triangular matrix\n\n";
for (@sampleList) {
    print "#$_\n";
}
print "\n";

for (my $i = 1; $i < scalar(@sampleList); $i++) {
    for (my $j = 0; $j < $i; $j++) {
         print $distHash{$sampleList[$i]}{$sampleList[$j]}{dist} /
              $distHash{$sampleList[$i]}{$sampleList[$j]}{compared};

        if($j != ($i + 1)) {
            print "\t";
        }
    }
    print "\n";
}
print "\n";


sub commify { # function stolen from web
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
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
