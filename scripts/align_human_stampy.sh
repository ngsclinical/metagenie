if [ -n "$7" ]
then

tmp_ref=`basename $7`; ref=`echo $tmp_ref | cut -d\. -f 1`;
tmp_read=`basename $4`; read=`echo $tmp_read | cut -d\. -f 1`;
#stampyPre=`echo ${5} | cut -d\. -f 1`;
gen_path=`dirname $7`;

$1 --bwaoptions="-q10 ${gen_path}/${ref}" --bwa=$2 -g ${gen_path}/${ref} -h ${gen_path}/${ref} -f sam --inputformat=fasta -M $4 2>>bwaerr | $3 view -S -f 4 -b -h - 2>>bwaerr | $3 sort - $5/${read}_${ref} 2>>bwaerr

$3 view $5/${read}_${ref}.bam |awk '{print ">"$1 "\n" $10}' > $5/${read}_${ref}.fasta

echo "Post process BWA with ${ref} alignment:" >> $6
echo "File generated: $5/${read}_${ref}.fasta  " >>$6
echo "Bam file: $5/${read}_${ref}.bam"  >>$6
echo "Total number of unmapped sequences"  >>$6
$3 view -c $5/${read}_${ref}.bam >>$6
rm $5/${read}_${ref}.bam;rm $4;
#2>&-;
else 
echo "No human reference genome set, Please see documentation";
fi

