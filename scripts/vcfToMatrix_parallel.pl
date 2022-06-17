#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use threads;
use Data::Dumper;


##############################
# By Matt Cannon
# Date: 
# Last modified: 
# Title: vcfToMatrix_parallel.pl
# Purpose: 
##############################

##############################
# Options
##############################
my $verbose;
my $help;
my $debug;
my $fileList;
my $chrStub = "chr";
my $threads = 1;
my $chrCount = 22;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "debug"             => \$debug,
            "fileList=s"        => \$fileList,
            "chrStub=s"         => \$chrStub,
            "threads=i"         => \$threads,
            "chromosomecount=i" => \$chrCount,
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my @resultsArray = ();
my @header;
my %varValueHash = ("0/0" => 0,
                    "0/1" => 1,
                    "1/1" => 2);
my @chromosomes = (1..$chrCount);

##############################
# Code
##############################


##############################
### Get header from VCF

my $cmd = "bcftools merge " . $fileList . " | head -n 10000 |grep '^#CHROM'";
my $headerLine = `$cmd`;
chomp $headerLine;

# pull sample names from header
@header = split(/\t/, $headerLine);
@header = @header[9..$#header];

#############################
### Create first batch of threads
my $done = 0;
my @workers = ();
# make first workers
for(my $i = 0; $i < $threads; $i++) {
    if (scalar(@chromosomes) > 0) {
        my $chr = $chrStub . shift(@chromosomes);
        $workers[$i] = threads->create({'scalar' => 1}, \&processVcfData, $fileList, $chr);
    }
}
############################
### Loop over threads and add more until all done
# Data is stored in @resultsArray which is an array of hashes
while($done == 0) {
    my $isDone = 1;
    # Loop through workers to see if they are already done or if need wrapped up
    # and start more if needed
    for(my $i = 0; $i < scalar(@workers); $i++) {
        if($workers[$i] ne "done") {
            if($workers[$i]->is_joinable()) {
                my $result = $workers[$i]->join();
                #print STDERR Dumper($result), " test dump\n" if ($debug);

                my %outhash = %$result;
                #print STDERR Dumper(\%outhash), " hash dump\n" if ($debug);

                push @resultsArray, { %outhash };

                print STDERR "Joined worker $i\n";
                $workers[$i] = "done";
                if(scalar(@chromosomes) > 0) {
                    my $chr = $chrStub . shift(@chromosomes);
                    $workers[$i] = threads->create({'scalar' => 1}, \&processVcfData, $fileList, $chr);
                    $isDone = 0;
                }
            } else {
                $isDone = 0;
            }
        }
    }
    if($isDone == 1) {
        $done = 1;
    }
}
#############################
### Merge hashes from @resultsArray
my %mergedHash;
foreach my $result (@resultsArray) {
    my %hash = %{$result};
    foreach my $key (keys %{ $hash{dist} }) {
        for my $key2 (keys %{ $hash{dist}{$key} }) {
            $mergedHash{dist}{$key}{$key2} += $hash{dist}{$key}{$key2};
            $mergedHash{comparisons}{$key}{$key2} += $hash{comparisons}{$key}{$key2};
        }
    }
}

print "#mega\nTITLE: Lower-left triangular matrix\n\n";
for (@header) {
    print "#$_\n";
}
print "\n";

# print out lower-left triangular matrix
for (my $i = 1; $i < scalar(@header); $i++) {
    for (my $j = 0; $j < $i; $j++) {
        print $mergedHash{dist}{$header[$i]}{$header[$j]} / $mergedHash{comparisons}{$header[$i]}{$header[$j]};

        if($j != ($i + 1)) {
            print "\t";
        }
    }
    print "\n";
}

###############################
### Subroutines
sub processVcfData {
    my $files = $_[0];
    my $chr = $_[1];

    my %distHash;
    my $commonLines = 0;
    my $totalLines = 0;
    my $informativeLines = 0;

    my $bcftoolsCmd = "bcftools merge --threads 5 -r " . $chr . " " . $files . " |";
    print STDERR $bcftoolsCmd, "\n" if ($debug);

    print STDERR "Processing $chr started\n" if ($verbose);

    open my $inputFH, $bcftoolsCmd or die "Could not open input file\n$!";
    while (my $inputLine = <$inputFH>) {
        if($inputLine !~ /INDEL/ && $inputLine !~ /^#/) { # kick out indels and comments
            chomp $inputLine;

            if ($inputLine =~ /GT:PL/) { # if likelihood was kept, get rid of it
                $inputLine =~ s/:.+?\t/\t/g;
                $inputLine =~ s/:.+$//;
            }

            my @inputLineArray = split("\t", $inputLine);
            if ($inputLineArray[4] !~ /,/) { # if there are multiple alleles, get rid of them
                $commonLines++;

                my @sampleArray = @inputLineArray[9..$#inputLineArray];
                my $joinedSamples = join("\t", @sampleArray);
                if ($joinedSamples =~ /0\/1/ || $joinedSamples =~ /1\/1/) {
                        $informativeLines++;
                        vcfDist(\@sampleArray, \%distHash);
                }
            }
            $totalLines++;
        }
        if ($verbose && $totalLines % 1000000 == 0 && $totalLines > 0) {
            print STDERR "Processed $chr: ",
                        "Common lines: ", commify($commonLines),
                        ". Total lines: ", commify($totalLines),
                        ". Informative lines: ", commify($informativeLines),
                        " \n";
        }
    }
    close $inputFH;
    return \%distHash;
}


sub vcfDist {
    my @inputArray = @{$_[0]};
    my $hashref = $_[1];

    for (my $i = 1; $i < scalar(@inputArray); $i++) {
        for (my $j = 0; $j < $i; $j++) {
            if ($inputArray[$i] ne "./." && $inputArray[$j] ne "./.") {
                $$hashref{dist}{$header[$i]}{$header[$j]} += abs($varValueHash{$inputArray[$i]} - $varValueHash{$inputArray[$j]});
                $$hashref{comparisons}{$header[$i]}{$header[$j]}++;
            }
        }
    }
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
