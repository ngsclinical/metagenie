if [ -n "$6" ]
then
for db in $6/*.bwt
do 
#tmpref=`basename ${db}`; ref=`echo $tmpref | cut -d\. -f 1`;
tmpref=`basename ${db}`; ref=`echo $tmpref | rev | cut -c 5-|rev`;
tmpread=`basename $3`; read=`echo $tmpread | cut -d\. -f 1`;

$1 aln -t 1 ${6}/${ref} $3 2>>bwaerr | $1 samse -n 150 -r '@RG\tID:Custom\tSM:Custom\tPL:ILLUMINA\n@PG\tID:BWA\tPN:BWA\tVN:0.5.9rc' ${6}/${ref} - $3 2>>bwaerr  | $2 view -b -S -u -h - 2>>bwaerr | $2 sort - $4/${read}_${ref} 2>>bwaerr
2>&-
$2 view -F 4 $4/${read}_${ref}.bam |awk '{print $1}' >> $4/${read}_${ref}_ALL_MAPPED_HEADER

$2 view -f 4 $4/${read}_${ref}.bam |awk '{print $1}' >> $4/${read}_${ref}_ALL_UNMAPPED_HEADER    

#$2 view -F 4 $4/${read}_${ref}.bam -o $4/${read}_${ref}_MAPPED.sam

echo "Post process BWA with ${ref}_${read} alignment:" >> $5
echo "Bam file: $4/${read}_${ref}.bam"  >>$5
echo "Total number of Unmapped sequences"  >>$5
$2 view -c -f 4 $4/${read}_${ref}.bam >>$5
echo "Total number of Mapped sequences"  >>$5
$2 view -c -F 4 $4/${read}_${ref}.bam >>$5

done
else 
echo "No valid Genomes found in the destination, Please see documentation: How to set Pathogen database";
fi