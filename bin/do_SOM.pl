#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use Data::Dumper;
use Time::HiRes;

use JSON::XS;

use lib ("../lib"); #Includes Supfam:: and TraP::
use Supfam::Utils qw(:all);
use Supfam::DataVisualisation;
use Supfam::SQLFunc qw(:all);

use lib ("../lib/TraP"); #Includes Cluster::
use Cluster::SOM;

use lib ("../lib/Supfam");

my %genes;
my %samples;
my %genes_tc;
my %samples_tc;
my %exps;
my %gene_d;
my %network_d;
my %tc_exps;
my %tc_sample;

my %exp_array;

my $dbh = dbTRAPConnect();

print "running....\n";

my $tic = Time::HiRes::time;

my $sth =   $dbh->prepare( "select experiment_id,raw_expression,gene_id from cell_snapshot;" );
#select riken_id,raw_expression,gene_id from cell_snap_shot

#Original sql used when working with rackhamdb. These tables should now be in tprot
#$sth =   $dbh->prepare( "select tprot.raw_data.sampleID, tprot.raw_data.groupID, tprot.raw_data.replica, tprot.raw_data.value, SUBSTRING(tprot.raw_data.GeneID,1,CHAR_LENGTH(tprot.raw_data.GeneID)-2) as a, rackham.ENT_lookup.GeneID from tprot.raw_data , rackham.ENT_lookup where SUBSTRING(tprot.raw_data.GeneID,1,CHAR_LENGTH(tprot.raw_data.GeneID)-2) = rackham.ENT_lookup.ENTID and SampleID = 2;" );

$sth->execute();
    
        while (my @temp = $sth->fetchrow_array ) {
			my $sample = $temp[0];
			$tc_exps{$temp[0]} = 1;
			$samples{$sample} =1;
			my $g = $temp[2];
			$genes{$g} = 1;
			if(exists($exps{$g}{$sample})){;
			$exps{$g}{$sample}= $exps{$g}{$sample} + $temp[1];
			}else{
			$exps{$g}{$sample}=$temp[1];
			}
        }
        
my $toc = Time::HiRes::time;
print "query returned in ".($toc-$tic)." seconds\n";
        
open(EXPS,'>exps.txt');

my $Names = join("\t", keys %genes); 
print EXPS "samples\t$Names\n";


foreach my $sample (keys %genes){
	print EXPS "$sample\t";

	foreach my $gene (keys %samples){
		if(exists($exps{$sample}{$gene})){
			if($exps{$sample}{$gene} == 0){
			print EXPS "NaN\t";
			push @{$exp_array{$sample}},$exps{$sample}{$gene};
			}else{
			print EXPS "$exps{$sample}{$gene}\t";
			push @{$exp_array{$sample}},$exps{$sample}{$gene};
			}
		}else{
			print EXPS "NaN\t";
			push @{$exp_array{$sample}},0;
		}

	}
	print EXPS "\n";

}

$tic = Time::HiRes::time;

my ($ClusterPositionsHash,$XYClusterGroups) = SOMcluster(\%exp_array,'s',0);

$toc = Time::HiRes::time;
print STDERR "Time taken to cluster data:".(($toc-$tic)/60)."minutes\n";


$tic = Time::HiRes::time;

EasyDump("./ClusterPositionsHash.dat", $ClusterPositionsHash);
EasyDump("./XYClusterGroups.dat", $XYClusterGroups);



my $utf8_encoded_json_text = JSON::XS->new->utf8->indent->encode ($XYClusterGroups);
#Example of how to dump ouput as JSON - this will likely be removed from the final version fo the script

$toc = Time::HiRes::time;
print STDERR "Time taken to dump data using Data::Dumper :".(($toc-$tic)/60)."minutes\n";





	
