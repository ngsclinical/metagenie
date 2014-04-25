#!/usr/bin/perl

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# Creates unmapped header index for extraction  
#######################################################################

use strict;

(open(mapFH, "<$ARGV[0]")) or die "Can't open file : $ARGV[0] \n";
(open(unmapFH,"<$ARGV[1]")) or die "Can't open file : $ARGV[1] \n";
(open(diffUnmapOF,"> $ARGV[2]")) or die "Cannot open file $ARGV[3]";

my (@isect,@map,@unmap,@unmapOnly) = ();
my (%union,%isect,%count) = ();

while (<mapFH>)
{
chomp ($_);	
push(@map,$_);
}
while (<unmapFH>)
{
chomp ($_);
push(@unmap,$_);
}

foreach my $cnt(@map, @unmap) { $count{$cnt}++ }

foreach my $cnt(keys %count) {
    if ($count{$cnt} == 2) {
        push @isect, $cnt;
    }
}


foreach my $cnt(@isect,@unmap) {$count{$cnt}++}

foreach my $cnt(keys %count) {
   if ($count{$cnt} == 2) {
	push @unmapOnly, $cnt;
			} 
   else {
	#do nothing
	}
}

for my $row(@unmapOnly)
{
	print diffUnmapOF $row, "\n";	
}

