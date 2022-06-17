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
my $debug;
my $inputList;
my $binSize = 1000;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "debug"             => \$debug,
            "inputFiles=s"      => \$inputList,
            "binSize=i"         => \$binSize
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my %storageHash;
my %sampleHash;
my $fileLineCounter = 0;

##############################
# Code
##############################


##############################
### Stuff
### More stuff

my $fileList = `ls $inputList`;

my @filesArray = split " ", $fileList;

for my $singleFile (@filesArray) {
    open my $singleFileFH, "$singleFile" or die "Could not open input\n$!";
    my $sampleName = $singleFile;
    $sampleName =~ s/_chr.+//;
    $sampleName =~ s/.+\///;

    $sampleHash{$sampleName} = 1;

    print STDERR $sampleName, "\n" if ($debug);
    print STDERR "\n" if ($verbose);

    my $junkHeader = <$singleFileFH>;

    while (my $input = <$singleFileFH>){
        chomp $input;
        my ($chrom, $chr_start, $chr_stop, $num_positions, $normal_depth,
            $tumor_depth, $adjusted_log_ratio, $gc_content, $region_call,
            $raw_ratio) = split "\t", $input;

        my $bin = int($chr_start / $binSize) * $binSize;
        push @{ $storageHash{$chrom . "\t" . $bin}{$sampleName} }, $adjusted_log_ratio;

        $fileLineCounter++;
        if ($verbose && $fileLineCounter % 100000 == 0) {
            print STDERR "\r", commify($fileLineCounter), " lines processed for $singleFile\r";
        }
    }
    if ($verbose) {
        print STDERR "\r", commify($fileLineCounter), " lines processed for $singleFile\r";
    }

    $fileLineCounter = 0;
}

print STDERR "\n", "Printing out results\n";

my @sampleArray = keys %sampleHash;

print "chr\tbin\t", join("\t", @sampleArray), "\n";

for my $chrBin (sort keys %storageHash) {
    print $chrBin;
    for my $sampleName (@sampleArray) {
        if (defined($storageHash{$chrBin}{$sampleName})) {
            print "\t", median(@{ $storageHash{$chrBin}{$sampleName} });
        } else {
            print "\t0";
        }
    }
    print "\n";
}

sub median {
    my @numArray = @_;
    @numArray = sort { $a <=> $b } @numArray;

    my $median;

    my $arrayLen = scalar(@numArray);

    if ($arrayLen == 1) {
        $median = $numArray[0];
    } elsif ($arrayLen == 0) {
        die "Empty array passed to subfunction median.\n";
    } elsif (($arrayLen % 2) == 0) {
        $median = ($numArray[($arrayLen / 2) - 1] + $numArray[($arrayLen / 2)]) / 2;
    } else {
        $median = $numArray[$arrayLen / 2];
    }
    return $median;
}

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
