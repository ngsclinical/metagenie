#!/usr/bin/perl

#######################################################################																	  
# Author: Arun Rawat, TGen 										 
# Wrapper script to run Read-Reduct and Patho-Detect        							  
#######################################################################


use Term::ANSIColor;
use strict;
use warnings FATAL => 'all';
use iconfig;
use Getopt::Long;
use Pod::Usage;
use File::Glob ':glob';

my $help="";
my $man="";
my $read_reduction="";
my $num_proc=1;
my $patho_detect="";
my $fasta_format="n";

GetOptions(
	'help|?' => \$help,
    'man' => \$man,
    'fa=s' => \$fasta_format,
    'np=i' => \$num_proc,
    'rr=s' => \$read_reduction,
    'pd=s' => \$patho_detect
    	  ) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

pod2usage(2) unless (1 == @ARGV);


my $bin_dir = $iconfig::bin_dir;

#my $input_file=$ARGV[0];
my $input_file=`basename $ARGV[0]`;
my @tmp_arr=split(/\./,$input_file);
my $input_file_prefix= $tmp_arr[0];


my $read_reduct_script="$bin_dir/readReduct.pl";
my $patho_detect_script = "$bin_dir/pathoDetect_v2.pl";

if ($read_reduction eq "n" or $read_reduction eq "N" )
{
	print color 'bold red'; 
	print "Skipping human read filteration and reduction\n";
	print color 'reset';
}
elsif ($read_reduction eq "y" or $read_reduction eq "Y" )
{
	system("$read_reduct_script","$fasta_format","$input_file", "$num_proc");
	print color 'bold blue';
	print "Human read filteration and reduction complete \n";
	print color 'reset';
	if ($patho_detect eq "y" or $patho_detect eq "Y" )
	{
			$input_file=$input_file_prefix."_readReduct.fasta";
			$fasta_format="y";
			system("$patho_detect_script","$fasta_format","$input_file", "$num_proc");
			print color 'bold blue';
			print "Pathogen Detection complete \n";
			print color 'reset';
	}
 exit 0;	
}

if ($patho_detect eq "n" or $patho_detect eq "N" )
{
	print color 'bold red';
	print "Skipping Pathogen Detection\n";
	print color 'reset';
}
elsif  ($patho_detect eq "y" or $patho_detect eq "Y" )
{
	system("$patho_detect_script","$fasta_format","$input_file", "$num_proc");
	print color 'bold blue';
	print "Pathogen Detection complete \n";
	print color 'reset';
}




__END__

=head1 NAME

metgenie.pl - Identification of metagenome sequences. MetGeniE consist of two modules: Read Reduction and Pathogen Detection. By default, both modules will be performed on the data. The User can switch on and off any of these modules according to the requirement. For more information please see the documentation.

=head1 SYNOPSIS

metgenie.pl [options] input_file

Options:
  -help
  -man

=head1 OPTIONS

=over 8

=item B<-help>

Brief help message

=item B<-man>

Full documentation

=item B<-fa str>

Input file format is fasta "y/Y" (Default fastq)

=item B<-np i>

Total number of processors to be used (Default 1)

=item B<-rr str>

Options "y/Y" or "N/n". Perform human read filtration and read reduction. Default yes 

=item B<-pd str>

Options "y/Y" or "N/n". Perform pathogen detection with known database. Default yes

=back

=head1 DESCRIPTION

B<metgenie.pl> Default mode, metgenie will filter human reads, identify metagenome reads

=head1 AUTHOR

Arun Rawat, C<< <arawat_atr_tgen_dot_org> >>

=head1 BUGS

Please report your bug/requirements at the email C<< <arawat_atr_tgen_dot_org> >>.

=head1 COPYRIGHT

Copyright (C) 2013-2014  Arun Rawat

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.


=cut
