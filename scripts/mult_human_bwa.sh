if [ -n "$6" ]
then
#for db in $6/*.bwt
#do
echo $6
ref=`echo $6 | cut -d\. -f 1`;
tmpref=`basename $6`; ref1=`echo $tmpref | cut -d\. -f 1`;
tmpread=`basename $3`; read=`echo $tmpread | cut -d\. -f 1`;

$1 aln -t 1 -q 15 $ref $3 2>bwaerr | $1 samse -r '@RG\tID:Custom\tSM:Custom\tPL:ILLUMINA\n@PG\tID:BWA\tPN:BWA\tVN:0.5.9rc' $ref - $3 2>bwaerr | $2 view -b -S -h -f 4 - 2>bwaerr | $2 sort - $4/${read}_${ref1} 2>bwaerr

$2 view $4/${read}_${ref1}.bam |awk '{print ">"$1 "\n" $10}' > $4/${read}_${ref1}.fasta

echo "Post process BWA with ${ref1} alignment:" >> $5
echo "File generated: $4/${read}_${ref1}.fasta  " >>$5
echo "Bam file: $4/${read}_${ref1}.bam"  >>$5
echo "Total number of unmapped sequences"  >>$5
$2 view -c $4/${read}_${ref1}.bam >>$5
rm $3; rm $4/${read}_${ref1}.bam;
#2>&-;
#done
else 
echo "No human reference genome set, Please see documentation";
fi
