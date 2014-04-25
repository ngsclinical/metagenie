#!/usr/bin/perl 

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# The script is invoked if Read-Reduct option is set yes
# Filters low quality, contaminants and human reads  
#######################################################################

use strict;
use warnings FATAL => 'all';
no warnings 'deprecated';
use iconfig;
use File::Basename;
use Parallel::ForkManager;
use File::Glob ':glob';
use POSIX qw( WNOHANG );

my %PID=();
my $wait_time=$iconfig::wait_time;
my $del_tmp_rr=$iconfig::del_tmp_rr;
my $min_len=$iconfig::min_len;
my $lc_method=$iconfig::lc_method;
my $lc_threshold=$iconfig::lc_threshold;
my $min_qual=$iconfig::min_qual;
my $ns_max_p=$iconfig::ns_max_p;
my $blat_identity = $iconfig::blat_identity;
my $run_bwa =$iconfig::run_bwa;
my $run_ref_hg19=$iconfig::run_ref_hg19;
my $run_ref_cn=$iconfig::run_ref_cn;
my $run_ref_kr=$iconfig::run_ref_kr;
my $run_ref_rep=$iconfig::run_ref_rep;
my $run_stampy=$iconfig::run_stampy;
my $run_dup_filter=$iconfig::run_dup_filter;

my @human_db=();
my ($human_ref_hg19,$human_ref_kr,$human_ref_cn,$repeat) ="";

if ($run_ref_hg19 eq "y" || $run_ref_hg19 eq "Y") {
	$human_ref_hg19 = $iconfig::human_ref_hg19;
	push(@human_db,$human_ref_hg19);
}

if ($run_ref_kr eq "y" || $run_ref_kr eq "Y") {	
	$human_ref_kr= $iconfig::human_ref_kr;
	push(@human_db,$human_ref_kr);
}

if ($run_ref_cn eq "y" || $run_ref_cn eq "Y") {
	$human_ref_cn=$iconfig::human_ref_cn;
	push(@human_db,$human_ref_cn);
}

if ($run_ref_rep eq "y" || $run_ref_rep eq "Y") {
	$repeat = $iconfig::repeat;
}

if (scalar(@human_db) == 0 || ! @human_db) {
	die "No Human Databases set, Please set to continue \n";
}

my $bin_dir = $iconfig::bin_dir;
my $script_dir = $iconfig::script_dir;
my $blat_exec = $iconfig::blat_exec;
my $aligner_exec = "";
my $samtools_exec=$iconfig::samtools_exec;
my $stampy_exec =$iconfig::stampy_exec;
my $prinseq_exec=$iconfig::prinseq_exec;
my $formatdb_exec=$iconfig::formatdb_exec;
my $fastacmd_exec=$iconfig::fastacmd_exec;
my $tmp_prinseq=$iconfig::tmp_prinseq_rr;
my $tmp_blat=$iconfig::tmp_blat_rr;
my $tmp_human_filter=$iconfig::tmp_human_filter;
my $log_folder=$iconfig::log_folder;
my $log_time=$iconfig::log_time;
my $log_distrib=$iconfig::log_distrib;
my $log_stats=$iconfig::log_stats;
my $frag_file_script = "$bin_dir/fragFile.pl";
my $psl_extract_script="$bin_dir/pslXtractor.pl";
my $xtract_Header_script="$bin_dir/xtractHeader.pl";
my $intersect_script="$bin_dir/intersect.pl";
my $mult_human_align ="";
my $aligner="";
my $aligner_bwa="";

if ($run_bwa eq "y" || $run_bwa eq "Y") {
	$aligner_exec = $iconfig::bwa_exec;
	$mult_human_align="$script_dir/mult_human_bwa.sh";
	$aligner="BWA";
}
else {
	$aligner_exec = $iconfig::bowtie2_exec;
	$mult_human_align="$script_dir/mult_human_bowtie.sh";
	$aligner="BOWTIE2";
}
$aligner_bwa = $iconfig::bwa_exec;
my $align_human_stampy="$script_dir/align_human_stampy.sh";
my $tmp_file_prefix="";
my $tmp_file_suffix="";
my @tmp_dir=($tmp_prinseq,$tmp_blat,$tmp_human_filter);
my $manager="";
my ($wait_msg, $log_msg, $pid)="";
my ($input_file, $output_file) = "";
my $sh_cmd = "";
my @cmd="";
my $fasta_format = $ARGV[0];
my $num_proc=$ARGV[2];
my @tmp_arr =();
my $input_file_prefix="";

foreach(@tmp_dir) {
	$tmp_file_prefix=$_;
	&makeDir($tmp_file_prefix);
} 
			  
unless(-d $log_folder) {
    mkdir $log_folder; 
}
else { 
	print "Using existing Log folder!!  \n"; 
}

open(timeLog, ">>$log_time") or die "Can't open file :$log_time \n";
open(logStats,">>$log_stats") or die "Can't open file :$log_stats \n";

print timeLog "The process started at:";
&timeStamp;

$input_file=`basename $ARGV[1]`;
@tmp_arr=split(/\./,$input_file);
$input_file_prefix= $tmp_arr[0];

$tmp_file_prefix="tmp_".$input_file_prefix;
@cmd=("$frag_file_script", "$input_file", "$tmp_file_prefix", "$tmp_prinseq", "$num_proc","$fasta_format");
system (@cmd)== 0 or &errorMessage("@cmd failed: $?");

my @files_in_folder=<$tmp_prinseq/*>;

&parallelManager_initiate;
foreach my $file(@files_in_folder) {
	$manager->start($file) and next;
	$tmp_file_prefix=fileparse($file);
	$tmp_file_suffix="tmp_clean";
	my $tmp_file=$tmp_file_prefix."_".$tmp_file_suffix;
	if ($fasta_format eq "y" || $fasta_format eq "Y" ) {
    	$sh_cmd="$prinseq_exec -log -fasta $file -min_len $min_len -rm_header -seq_id $tmp_file_prefix -lc_threshold $lc_threshold -lc_method dust -out_good $tmp_prinseq/$tmp_file -ns_max_p $ns_max_p -out_format 1 -out_bad null";
	}
	else {
		$sh_cmd ="$prinseq_exec -log -fastq $file -min_qual_score $min_qual -min_len $min_len -rm_header -seq_id $tmp_file_prefix -lc_threshold $lc_threshold -lc_method dust -out_good $tmp_prinseq/$tmp_file -ns_max_p $ns_max_p -out_format 1 -out_bad null";
	}
    system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
	if ($manager) {$manager->finish($pid)};
}
$wait_msg="Performing removal of low quality reads ...\n";
$manager->wait_all_children;

my @tmpfiles=glob("$tmp_prinseq/*tmp_clean.fasta");
$output_file=$input_file_prefix."_clean.fasta";

for my $file(@tmpfiles) {
	$sh_cmd="cat $file >> $output_file";
	system($sh_cmd) == 0 or &errorMessage(" $sh_cmd failed: $?");
}
if ($fasta_format eq "y" || $fasta_format eq "Y" ) {
	@tmpfiles=glob("$tmp_prinseq/*.fasta");
}
elsif ($fasta_format eq "n" || $fasta_format eq "N") {
	@tmpfiles=glob("$tmp_prinseq/*.fastq");
}

for my $file(@tmpfiles) {
	unlink "$file" or warn "Can't delete $file: $!";
}
$log_msg="Total sequences after removal of low quality reads:";
#print $log_msg;
&seqCount_fasta($log_msg,$output_file);

print timeLog "The sequence cleaning done:";
&timeStamp;

$input_file=$output_file;

	$tmp_file_prefix="tmpBWAHuman_".$input_file_prefix;
	$fasta_format="y";
	@cmd=("$frag_file_script", "$input_file", "$tmp_file_prefix", "$tmp_human_filter", "$num_proc","$fasta_format");
	system (@cmd) == 0 or &errorMessage("@cmd failed: $?");

if ($del_tmp_rr eq "y" || $del_tmp_rr eq "Y") {	
	unlink "$input_file" or warn "Can't delete $input_file: $!";
}
	foreach(@human_db) {
		my $tmp_human_db=$_;
		if (-e $tmp_human_db) {			
			@files_in_folder=<$tmp_human_filter/*>;
			&parallelManager_initiate;
			foreach my $file(@files_in_folder) {
				$manager->start($file) and next;
				@cmd=("$mult_human_align", "$aligner_exec", "$samtools_exec", "$file", "$tmp_human_filter", "$log_distrib", "$tmp_human_db");
				system(@cmd)== 0 or &errorMessage("@cmd failed: $?");
				if ($manager) {$manager->finish($pid)};
			}
			$wait_msg="Running alignment against Human Genomes with $aligner ...\n";
			$manager->wait_all_children;
		}		
		else {
			die "Please set the $tmp_human_db corectly in Configuration file!!  \n";
		}
	} 
			  
@tmpfiles=glob("$tmp_human_filter/*.fasta");
$output_file=$input_file_prefix."_unmap_human_bwa.fasta";
for my $file(@tmpfiles) {
	$sh_cmd= "cat $file >> $output_file";
	system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
 	unlink "$file" or warn "Can't delete $file: $!";
}
$log_msg="Total sequences after $aligner alignment against Human Genomes:";
&seqCount_fasta($log_msg,$output_file);
print timeLog "The human alignment with BWA finished:";
&timeStamp;

if ($run_dup_filter eq "Y" || $run_dup_filter eq "y") {
	$input_file=$output_file;
	$output_file =$input_file_prefix."_rm_dup";
	$sh_cmd = "$prinseq_exec -log -fasta $input_file -rm_header -seq_id $tmp_file_prefix -derep 12345 -out_good $output_file -out_format 1 -out_bad null";
	system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
	if ($del_tmp_rr eq "y" || $del_tmp_rr eq "Y") {	
		unlink "$input_file" or warn "Can't delete $input_file: $!";
	}
	$log_msg="Total sequences after removal of duplicates:";
	$output_file=$output_file.".fasta";
	&seqCount_fasta($log_msg,$output_file);
	print timeLog "The duplicates removal completed:";
	&timeStamp;
}
else {
	print logStats "Usage of Duplicate Removal turned OFF!! \n";	
}


if ($run_stampy eq "y" || $run_stampy eq "Y") {	
	$input_file=$output_file;
	$tmp_file_prefix="tmpSTAMPYHuman_".$input_file_prefix;
	@cmd=("$frag_file_script", "$input_file", "$tmp_file_prefix", "$tmp_human_filter", "$num_proc","$fasta_format");
	system (@cmd)== 0 or &errorMessage("@cmd failed: $?");
	if ($del_tmp_rr eq "y" || $del_tmp_rr eq "Y") {	
		unlink "$input_file" or warn "Can't delete $input_file: $!";
	}
	my $tmp_human_db=$human_db[0];
	unless (-e $tmp_human_db) {	
		die "Please set the $tmp_human_db corectly in Configuration file!!  \n";
	}

	@files_in_folder=<$tmp_human_filter/*>;
	&parallelManager_initiate;
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		@cmd=("$align_human_stampy", "$stampy_exec", "$aligner_bwa", "$samtools_exec", "$file", "$tmp_human_filter", "$log_distrib", "$human_ref_hg19");
		system(@cmd)== 0 or &errorMessage("@cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Running alignment against Human Genomes with STAMPY ...\n";
	$manager->wait_all_children;

	@tmpfiles=glob("$tmp_human_filter/tmpSTAMPYHuman_*.fasta");
	$output_file=$input_file_prefix."_unmap_human_stampy.fasta";
	for my $file(@tmpfiles) {
		$sh_cmd = "cat $file >> $output_file";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
		unlink "$file" or warn "Can't delete $file: $!";
	}
	$log_msg="Total sequences after STAMPY alignment against Human Genome:";
	&seqCount_fasta($log_msg,$output_file);
	print timeLog "The human alignment with STAMPY finished:";
	&timeStamp;
}
else {
	print logStats "Usage of sensitive alignment with STAMPY turned OFF!! \n";	
}

if($run_ref_rep eq "y" || $run_ref_rep eq "Y") {
	$input_file=$output_file;
	$output_file=$input_file_prefix."_unmap_repeat_blat.fasta";
	&runBlat($input_file,$repeat,$output_file);
	if ($del_tmp_rr eq "y" || $del_tmp_rr eq "Y") {	
		unlink "$input_file" or warn "Can't delete $input_file: $!";
	}
	$log_msg="Total sequences after removal of Human Repeats with BLAT:";
	&seqCount_fasta($log_msg,$output_file);
}
else{
	print logStats "Querying Human Repeat Database turned OFF !! \n";		
}

my $final_out_file=$input_file_prefix."_readReduct.fasta";
rename($output_file,$final_out_file);
&closeFiles;

sub runBlat {
	my ($input,$ref,$output)=@_;
	$tmp_file_prefix="tmpBLATHumanGenome_".$input_file_prefix;
	@cmd=("$frag_file_script", "$input", "$tmp_file_prefix", "$tmp_blat", "$num_proc","$fasta_format");
	system (@cmd)== 0 or &errorMessage("@cmd failed: $?");
	@files_in_folder=<$tmp_blat/*>;
	&parallelManager_initiate;
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$blat_exec $ref -minIdentity=$blat_identity -noHead $file $file.psl";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Running Human Genome Alignment with BLAT ...\n";
	$manager->wait_all_children;

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.psl");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		@cmd=("$psl_extract_script", "$file", "$file.MAPPED");
		system(@cmd)== 0 or &errorMessage("@cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Extracting and finalizing BLAT hits ...\n";
	$manager->wait_all_children;

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		@cmd=("$xtract_Header_script", "$file", "$file.HEADER.ALL");
		system(@cmd)== 0 or &errorMessage("@cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Extracting headers ...\n";
	$manager->wait_all_children;
	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		@cmd=("$intersect_script", "$file.psl.MAPPED", "$file.HEADER.ALL", "$file.psl.UNMAPPED");
		system(@cmd)== 0 or &errorMessage("@cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Extracting unmapped headers ...\n";
	$manager->wait_all_children;

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$formatdb_exec -p F -o T -i $file";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Setting databases ...\n";
	$manager->wait_all_children;

	&parallelManager_initiate;
	@files_in_folder=glob("$tmp_blat/*.fasta");
	foreach my $file(@files_in_folder) {
		$manager->start($file) and next;
		$sh_cmd="$fastacmd_exec -p F -d $file -i $file.psl.UNMAPPED -o $file.psl.UNMAPPED_SEQ 2>>$tmp_blat/db_log";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
		if ($manager) {$manager->finish($pid)};
	}
	$wait_msg="Extracting unmapped reads ...\n";
	$manager->wait_all_children;

	@tmpfiles=glob("$tmp_blat/*.psl.UNMAPPED_SEQ");
	for my $file(@tmpfiles) {
		$sh_cmd="cat $file >> $output";
		system($sh_cmd)== 0 or &errorMessage(" $sh_cmd failed: $?");
		unlink "$file" or warn "Can't delete $file: $!";
	}

	@tmpfiles=glob("$tmp_blat/*");
	for my $file(@tmpfiles) {
		unlink "$file" or warn "Can't delete $file: $!";
	}
	print timeLog "The human genome alignment with BLAT finished:";
	&timeStamp;
}

sub seqCount_fasta {
	my $msg=shift;
	my $file=shift;
	(open(IN, "<$file"));
	my $cnt=0;
	while (<IN>) {
		if ($_ =~ /^\>/) {
			$cnt++;
		}
	}
	print logStats "$msg",$cnt,"\n";
	close IN;
}

sub parallelManager_initiate {
	$manager = new Parallel::ForkManager($num_proc);
}

sub parallelManager_wait {
	$manager->run_on_wait(
    	sub {
      		print $wait_msg;
    	}, $wait_time
  	);
	$manager->wait_all_children;
}

sub makeDir {
	my $dir=shift;
	unless(-d $dir) {
		mkdir $dir;    
	} 
	else { 
		die "Temp Directories already exists, Please delete or rename Folders!!  \n"; 
	} 
}

sub timeStamp {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,
	$yday,$isdst)=localtime(time);

	printf timeLog "%4d-%02d-%02d %02d:%02d:%02d\n",
	$year+1900,$mon+1,$mday,$hour,$min,$sec;
}

sub errorMessage {
    my $err = shift;
    print STDERR "\n\n ERROR: ".$err.".\n\n Please see IRIMAS documentation or \'irimas -h\' for info.\n EXITING on ERROR.\n";
    exit(0);
}

sub closeFiles {
	close timeLog;
	close logStats;
}
