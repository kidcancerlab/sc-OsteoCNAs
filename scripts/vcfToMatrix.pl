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
my $input;

# i = integer, s = string
GetOptions ("verbose"           => \$verbose,
            "help"              => \$help,
            "debug"             => \$debug,
            "input=s"           => \$input
      ) or pod2usage(0) && exit;

pod2usage(1) && exit if ($help);


##############################
# Global variables
##############################
my %distHash;
my @header;
my $commonLines = 0;
my $totalLines = 0;
my $informativeLines = 0;
my $nonInformativeExample;
my %varValueHash = ("0/0" => 0,
                    "0/1" => 1,
                    "1/1" => 2);

##############################
# Code
##############################


##############################
### Stuff
### More stuff

open my $inputFH, $input or die "Could not open input file\n$!";
while (my $inputLine = <$inputFH>) {
    if ($inputLine =~ /\#CHROM/) {
        chomp $inputLine;
        # pull sample names from header
        @header = split(/\t/, $inputLine);
        @header = @header[9..$#header];
        $nonInformativeExample = join("\t", ("0/0") x scalar(@header));
    } elsif($inputLine !~ /INDEL/ && $inputLine !~ /^#/) { # kick out indels and comments
        chomp $inputLine;

        if ($inputLine =~ /GT:PL/) { # if likelihood was kept, get rid of it
            $inputLine =~ s/:.+?\t/\t/g;
            $inputLine =~ s/:.+$//;
        }

        my @inputLineArray = split("\t", $inputLine);
        if ($inputLineArray[4] !~ /,/) { # if there are multiple alleles, get rid of them
            my @sampleArray = @inputLineArray[9..$#inputLineArray];
            my $joinedSamples = join("\t", @sampleArray);
            if ($joinedSamples =~ /0\/1/ || $joinedSamples =~ /1\/1/) {
                    $informativeLines++;
                    vcfDist(\@sampleArray);
            }
        }
        $totalLines++;
    }
    if ($verbose && $totalLines % 100000 == 0) {
        print STDERR "Processed: ",
                     "Common lines: ", commify($commonLines),
                     ". Total lines: ", commify($totalLines),
                     ". Informative lines: ", commify($informativeLines), "\r";
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
        print $distHash{dist}{$header[$i]}{$header[$j]} / $distHash{comparisons}{$header[$i]}{$header[$j]};

        if($j != ($i + 1)) {
            print "\t";
        }
    }
    print "\n";
}

print STDERR "Common lines: ", commify($commonLines),
             ". Total lines: ", commify($totalLines),
             ". Informative lines: ", commify($informativeLines), "\n";

###############################
### Subroutines

sub vcfDist {
    my @inputArray = @{$_[0]};
    print STDERR join("\t", @inputArray), "infunction\n" if ($debug);
    my $dist = 0;
    for (my $i = 1; $i < scalar(@inputArray); $i++) {
        for (my $j = 0; $j < $i; $j++) {
            if ($inputArray[$i] ne "./." && $inputArray[$j] ne "./.") {
                $distHash{dist}{$header[$i]}{$header[$j]} += abs($varValueHash{$inputArray[$i]} - $varValueHash{$inputArray[$j]});
                $distHash{comparisons}{$header[$i]}{$header[$j]}++;
            }
            # $dist = abs($varValueHash{$inputArray[$i]} - $varValueHash{$inputArray[$j]});
            # $distHash{$header[$i]}{$header[$j]} += $dist;
        }
    }
}

sub commify { # function stolen from web
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}


#open R1OUTFILE, ">", $outputNameStub . "_R1.fastq";

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
