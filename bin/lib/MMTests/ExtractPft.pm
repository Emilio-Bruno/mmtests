# ExtractPft.pm
package MMTests::ExtractPft;
use MMTests::SummariseMultiops;
our @ISA = qw(MMTests::SummariseMultiops);

use MMTests::Stat;
use strict;

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	$self->{_ModuleName} = "ExtractPft";
	$self->{_DataType}   = DataTypes::DATA_OPS_PER_SECOND;
	$self->{_PlotType}   = "client-errorlines";
	$self->{_Precision} = 4;
	$self->{_FieldLength} = 14;
	$self->SUPER::initialise($reportDir, $testName);
}

my $_pagesize = "base";

sub extractReport() {
	my ($self, $reportDir) = @_;
	my ($user, $system, $wallTime, $faultsCpu, $faultsSec);
	my $dummy;
	$reportDir =~ s/pfttime-/pft-/;

	my @clients;
	my @files = <$reportDir/$_pagesize/pft-*.log>;
	foreach my $file (@files) {
		my @split = split /-/, $file;
		$split[-1] =~ s/.log//;
		push @clients, $split[-1];
	}
	@clients = sort { $a <=> $b } @clients;

	foreach my $client (@clients) {
		my $nr_samples = 0;
		my $file = "$reportDir/$_pagesize/pft-$client.log";
		open(INPUT, $file) || die("Failed to open $file\n");
		while (<INPUT>) {
			my $line = $_;
			$line =~ tr/s//d;
			if ($line =~ /[a-zA-Z]/) {
				next;
			}

			# Output of program looks like
			# MappingSize  Threads CacheLine   UserTime  SysTime WallTime flt/cpu/s fault/wsec
			($dummy, $dummy, $dummy, $dummy,
		 	$user, $system, $wallTime,
		 	$faultsCpu, $faultsSec) = split(/\s+/, $line);

			$nr_samples++;
			$self->addData("faults/cpu-$client", $nr_samples, $faultsCpu);
			$self->addData("faults/sec-$client", $nr_samples, $faultsSec);
		}
		close INPUT;
	}

	my @ops;
	foreach my $heading ("faults/cpu", "faults/sec") {
		foreach my $client (@clients) {
			push @ops, "$heading-$client";
		}
	}
	$self->{_Operations} = \@ops;
}

1;
