use Bio::SeqIO;

my $ARGCNT = $#ARGV + 1;
if ($ARGCNT != 2)
{
        print "usage: perl <perl_script> <FastaFile> <outputfile> 
\n";
            exit(1);
}
	
	my $fileOut = $ARGV[1];
	open(OF, ">>$fileOut") or die "Can't open file :$fileOut \n";
	my $seq_in= Bio::SeqIO->new(-file=>$ARGV[0],'-format'=>'Fasta');
	#my $seq;
    my @seq_array;
    my $seq_desc;
    my $cnt=$seq_cnt=0;
    my $seq_str;
	 while( my $seq = $seq_in->next_seq() ) 
	 {
		$seq_desc=$seq->desc();
		chomp($seq_desc);
		$seq_desc =~ s/\; //g;
		@seq_array = split(/ /, $seq_desc);
		$seq_cnt=scalar(@seq_array);
		while ($cnt<$seq_cnt)
		{
			if ($cnt==0)
			{
				$seq_str=$seq_array[$cnt]."_#_";
			}
			elsif ($cnt==1)
			{
				$seq_str=$seq_str.$seq_array[$cnt]."_!_";
			}
			elsif ($cnt==2)
			{
				$seq_str=$seq_str.$seq_array[$cnt]."_{_";
			}
			elsif ($cnt==3)
                        { 
                                $seq_str=$seq_str.$seq_array[$cnt]."_}_";
                        }
			elsif($cnt==($seq_cnt-1))
			{
				$seq_str=$seq_str.$seq_array[$cnt];
			}
			else
			{
				$seq_str=$seq_str.$seq_array[$cnt]."_";
			}
		$cnt++;	
		}
		$seq_str =~ s/\,//g;
        #$seqValues[0]=~ s/ /_/g;
        #$seq_desc=substr($seq_desc,0,70); 
        #print $seq_desc,"\t",$cnt, "\t".$seq_str. "\n";
		print OF ">",$seq_str,"|",$seq->id,  "\n";
     	 	$seqstring=$seq->seq;
      		$count = length($seqstring);
      		$modulus = $count % 150;
      		$loop = $count/150;
      		if ($modulus)
	        {
	            ## write the seqname and string to new file
	            $loop+=1;
	        }
	  	$loopcounter=0;
	  	$offset=0;
	  
			do 
			{
				$substring = substr($seqstring, $offset, 150);	
				print OF "$substring" . "\r\n";
				$offset+=150;
				$loopcounter++;
			}
	        while ($loopcounter < $loop);
      
      #print OF $seqstring, "\n";
     $cnt=0; 		
      	}
