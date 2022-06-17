#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use threads;


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
my $normal;
my $tumor;
my $proportionKept = 1;
my $viewThreads = 1;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "normal=s"          => \$normal,
            "tumor=s"           => \$tumor,
            "proportionKept=s"  => \$proportionKept,
            "viewThreads=i"     => \$viewThreads
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################

##############################
# Code
##############################
# Let me pull in bam files
$normal =~ s/(.*\.bam)\s*$/samtools view -@ $viewThreads < $1|/;
$tumor =~ s/(.*\.bam)\s*$/samtools view -@ $viewThreads < $1|/;

if ($proportionKept != 1) {
    $normal =~ s/samtools view/samtools view -s $proportionKept/;
    $tumor =~ s/samtools view/samtools view -s $proportionKept/;
}
##############################
### Stuff
### More stuff

my $normalThread = threads->create(\&countCov, $normal);
my $tumorThread = threads->create(\&countCov, $tumor);

my $normalCov;
my $tumorCov;

my $doneCount = 0;
while ($doneCount < 2) {
    if ($normalThread->is_joinable() ){
        $normalCov = $normalThread->join();
        $doneCount++;
    }
    if ($tumorThread->is_joinable() ){
        $tumorCov = $tumorThread->join();
        $doneCount++;
    }
    sleep(5);
}

print $normalCov / $tumorCov;

sub countCov {
    my $fileName = $_[0];

    my $fileStub = $fileName;
    $fileStub =~ s/.+ < //;
    $fileStub =~ s/\|//;

    my $totalCoverage = 0;
    my $counter = 0;

    open my $fileNameFH, "$fileName" or die "Could not open input\n$!";
    while (my $input = <$fileNameFH>){
        chomp $input;
        my ($qname, $flag, $rname, $pos, $mapq, $cigar, $rnext, $pnext, $tlen, $seq, $qual) = split "\t", $input;

        # Is mapped
        if ($rname ne "*") {
            $totalCoverage += length($seq);
        }
        # at some point I may need to account for:
            # - soft trimming
            # - multi-mapped reads
            # - overlapping paired reads
        if ($verbose) {
            $counter++;
            print STDERR commify($counter), " reads counted for $fileStub\n" if ($counter % 1000000 == 0);
        }
    }
    print STDERR commify($counter), " reads counted for $fileStub\n" if ($verbose);
    return $totalCoverage;
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
    
    xxxxxx.pl - generates a consensus for a specified gene in a specified taxa
    
Usage:

    perl xxxxxx.pl [options] 


=head OPTIONS

Options:

    --verbose
    --help

=cut
