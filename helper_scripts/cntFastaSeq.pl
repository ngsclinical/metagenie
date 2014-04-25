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

	
	 my $seq;
     my @seq_array;
	 while( $seq = $seq_in->next_seq() ) {

      print OF $seq->id,$seq->desc, "\t", $seq->length , "\n";

    }
