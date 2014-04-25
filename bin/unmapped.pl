use File::Glob qw[glob];

&parallelManager_initiate;
@files_in_folder=glob("tmp_bwa_bacteria/*_ALL_UNMAPPED");
foreach my $unmap_file(@files_in_folder) {
$manager->start($file) and next;
		for (my $tmp_outer = 1; $tmp_outer<=$db_partition; $tmp_outer++) {
			$tmp_in=$fasta_file."_".$tmp_inner."_".$tmp_outer.".psl.MAPPED";
			$sh_cmd ="cat $tmp_in >> $fasta_file.psl.MAPPED";
			system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
			
		}
		if ($manager) {$manager->finish($pid)};
		$tmp_inner++;
		}
		$wait_msg="Generating Unique IDs per partition ...\n";
	$manager->wait_all_children;
	print $wait_msg;


one per sample: cp ../ERR191896/aspen_id.pbs .

mkdir id_95 id_99
cp id_90/iconfig.pm id_95
cp id_90/iconfig.pm id_99

ln -s ../../aspen_id.pbs
ln -s ../ERR191896_readReduct.fasta 

change parameter
run files
		