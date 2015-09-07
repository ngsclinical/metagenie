#!/usr/bin/perl

###################################################################
## http://davetang.org/muse/2012/05/15/using-blat/(external link)**
#Converts psl file into a bed file storing only the best scoring match/es
###################################################################

use strict;
use warnings;

my $usage = "Usage: $0 <in.psl> <out.bed>\n";
my $infile = shift or die $usage;
my $outfile = shift or die $usage;

open(OUT, '>', $outfile) || die "Could not open $outfile for writing: $!\n";

my %psl_result = ();
my $red = '255,0,0';

open(IN, '<', $infile) || die "Could not open $infile: $!\n";
while (<IN>) {
   chomp;

   #Skip header
   next if (/^psL/ || /^match/ || /^\s+match/ || /^----/ || /^$/);
   my $current_line = $_;

   my ($matches,$misMatches,$repMatches,$nCount,$qNumInsert,$qBaseInsert,$tNumInsert,$tBaseInsert,$strand,$qName,$qSize,$qStart,$qEnd,$tName,$tSize,$tStart,$tEnd,$blockCount,$blockSizes,$qStarts,$tStarts) = parse_psl($current_line);

   #Calculate score for this match (based on UCSC blat)
   my $sizeMul = 1; #This is 1 for dna and 3 for protein
   my $score = ($sizeMul * ($matches + $repMatches)) - ($sizeMul * $misMatches) - $qNumInsert - $tNumInsert;
   #print "$qName\t$score\n";

   if (exists $psl_result{$qName}){
      foreach my $prevScore (keys %{$psl_result{$qName}}){
         if ($score > $prevScore){
            delete $psl_result{$qName}{$prevScore};
            $psl_result{$qName}{$score}->['0'] = $current_line;
         }
         elsif ($score == $prevScore){
            my $num = scalar @{$psl_result{$qName}{$score}};
            $psl_result{$qName}{$score}->[$num] = $current_line;
         }
      }
   }
   else {
      $psl_result{$qName}{$score}->['0'] = $current_line;
   }
}
close(IN);

foreach my $query (keys %psl_result){
   foreach my $score (keys %{$psl_result{$query}}){
      #print "$query\t$score\n";
      for (my $i = 0; $i < scalar (@{$psl_result{$query}{$score}}); ++$i){
         #print "#$i\t$psl_result{$query}{$score}->[$i]\n";
         my $result = $psl_result{$query}{$score}->[$i];
         my ($matches,$misMatches,$repMatches,$nCount,$qNumInsert,$qBaseInsert,$tNumInsert,$tBaseInsert,$strand,$qName,$qSize,$qStart,$qEnd,$tName,$tSize,$tStart,$tEnd,$blockCount,$blockSizes,$qStarts,$tStarts) = parse_psl($result);

         #Hack for affy
         $qName =~ s/;$//;

=head2 sample psl output

psLayout version 3

match   mis-    rep.    N's     Q gap   Q gap   T gap   T gap   strand  Q               Q       Q       Q       T               T       T       T       blockblockSizes      qStarts  tStarts
        match   match           count   bases   count   bases           name            size    start   end     name            size    start   end     count
---------------------------------------------------------------------------------------------------------------------------------------------------------------
277     18      0       0       5       205     7       94737   +       consensus:HG-U133A_2:212917_x_at;       935     18      518     chr1    249250621   101179037        101274069       9       53,59,22,28,62,7,11,47,6,       18,71,150,332,371,433,453,464,512,      101179037,101179093,101179170,101273881,101273923,101273986,101274001,101274016,101274063,
160     11      0       0       3       63      4       63      +       consensus:HG-U133A_2:212917_x_at;       935     327     561     chr1    249250621   37924385 37924619        5       41,53,56,14,7,  327,379,462,540,554,    37924385,37924439,37924532,37924595,37924612,
237     17      0       0       3       231     6       27269   -       consensus:HG-U133A_2:212917_x_at;       935     38      523     chr1    249250621   49391110 49418633        8       61,9,5,52,43,57,16,11,  412,488,497,502,554,812,869,886,        49391110,49391177,49391189,49391200,49391255,49418546,49418606,49418622,
176     10      0       1       2       25      3       9       -       consensus:HG-U133A_2:212917_x_at;       935     342     554     chr1    249250621   24751715 24751911        5       14,58,16,19,80, 381,415,473,494,513,    24751715,24751732,24751793,24751809,24751831,
277     18      0       0       5       205     7       94737   +       consensus:HG-U133A_2:212918_at; 935     18      518     chr1    249250621       101179037    101274069       9       53,59,22,28,62,7,11,47,6,       18,71,150,332,371,433,453,464,512,      101179037,101179093,101179170,101273881,101273923,101273986,101274001,101274016,101274063,

=cut

=head2

BED format

chrom - The name of the chromosome (e.g. chr3, chrY, chr2_random) or scaffold (e.g. scaffold10671).
chromStart - The starting position of the feature in the chromosome or scaffold. The first base in a chromosome is numbered 0.
chromEnd - The ending position of the feature in the chromosome or scaffold. The chromEnd base is not included in the display of the feature. For example, the first 100 bases of a chromosome are defined as chromStart=0, chromEnd=100, and span the bases numbered 0-99.

The 9 additional optional BED fields are:
name - Defines the name of the BED line. This label is displayed to the left of the BED line in the Genome Browser window when the track is open to full display mode or directly to the left of the item in pack mode.
score - A score between 0 and 1000. If the track line useScore attribute is set to 1 for this annotation data set, the score value will determine the level of gray in which this feature is displayed (higher numbers = darker gray). This table shows the Genome Browser's translation of BED score values into shades of gray: shade
score in range          . 166   167-277 278-388 389-499 500-611 612-722 723-833 834-944 . 945


strand - Defines the strand - either '+' or '-'.
thickStart - The starting position at which the feature is drawn thickly (for example, the start codon in gene displays).
thickEnd - The ending position at which the feature is drawn thickly (for example, the stop codon in gene displays).
itemRgb - An RGB value of the form R,G,B (e.g. 255,0,0). If the track line itemRgb attribute is set to "On", this RBG value will determine the display color of the data contained in this BED line. NOTE: It is recommended that a simple color scheme (eight colors or less) be used with this attribute to avoid overwhelming the color resources of the Genome Browser and your Internet browser.
blockCount - The number of blocks (exons) in the BED line.
blockSizes - A comma-separated list of the block sizes. The number of items in this list should correspond to blockCount.
blockStarts

=cut

         my @splitBlockSizes = split(/,/,$blockSizes);
         my @split_target_block_start = split(/,/,$tStarts);

         #For converting to the bed file it is easy
         #The tBlocks are given in the positive direction, regardless of mapping to the negative strand
         #tStarts + $blockSizes will be the exon
         #However, BED chromStarts offsets must be relative to chromStart, not absolute. Try subtracting chromStart from each offset in chromStarts.
         my $relative_t_starts = '';
         foreach my $psl_t_starts (@split_target_block_start){
            my $sub = $psl_t_starts - $tStart;
            $relative_t_starts .= "$sub,";
         }
         $relative_t_starts =~ s/,$//;
         #For UCSC Genome Browser add 1 to end
         $tEnd += 1;
         #BED  chrom,chromStart,chromEnd,name  ,score ,strand ,thickStart,thickEnd,itemRgb,blockCount ,blockSizes ,blockStarts
         #print OUT join("\t",$tName,$tStart   ,$tEnd   ,$qName,$score,$strand,$tStart   ,$tEnd   ,$red   ,$blockCount,$blockSizes,$relative_t_starts),"\n";
         #### MODIFICATION START###

	my $span=abs($qEnd-$qStart);
        $span=$tStart+$span;
 	#print join("\t",$tName,$qStart   ,$qEnd   ,$tStart, $span, $qName,$score,$strand),"\n";
        print OUT join("\t",$tName,$tStart   ,$span   ,$qName,$score,$strand),"\n";
	####MODIFICATION END#####	 
         #For GFF
         #for (my $j = 0; $j < $blockCount; ++$j){
         #   my $tBlockEnd = $split_target_block_start[$j] + $splitBlockSizes[$j];
         #   print OUT "$tName\tblat\tmm9genome\t$split_target_block_start[$j]\t$tBlockEnd\t$score\t$strand\t.\t${qName}_$i\n";
         #}
      }
   }
}
exit(0);

sub parse_psl {
   my ($line) = @_;
   my @result = split(/\t/,$line);
   my $matches = $result[0];     #Number of bases that matches the query matched to the target
   my $misMatches = $result[1];  # Number of bases that don't match
   my $repMatches = $result[2];  # Number of bases that match but are part of repeats
   my $nCount = $result[3];      # Number of 'N' bases
   my $qNumInsert = $result[4];  # Number of inserts in query
   my $qBaseInsert = $result[5]; # Number of bases inserted in query
   my $tNumInsert = $result[6];  # Number of inserts in target
   my $tBaseInsert = $result[7]; # Number of bases inserted in target
   my $strand = $result[8];      # '+' or '-' for query strand. For translated alignments, second '+'or '-' is for genomic strand
   my $qName = $result[9];       # Query sequence name
   my $qSize = $result[10];      # Query sequence size
   my $qStart = $result[11];     # Alignment start position in query
   my $qEnd = $result[12];       # Alignment end position in query
   my $tName = $result[13];      # Target sequence name
   $tName =~ s/\.fa$//;
   my $tSize = $result[14];      # Target sequence size
   my $tStart = $result[15];     # Alignment start position in target
   my $tEnd = $result[16];       # Alignment end position in target
   my $blockCount = $result[17]; # Number of blocks in the alignment (a block contains no gaps)
   my $blockSizes = $result[18]; # Comma-separated list of sizes of each block
   my $qStarts = $result[19];    # Comma-separated list of starting positions of each block in query
   my $tStarts = $result[20];    # Comma-separated list of starting positions of each block in target
   return($matches,$misMatches,$repMatches,$nCount,$qNumInsert,$qBaseInsert,$tNumInsert,$tBaseInsert,$strand,$qName,$qSize,$qStart,$qEnd,$tName,$tSize,$tStart,$tEnd,$blockCount,$blockSizes,$qStarts,$tStarts);
}
