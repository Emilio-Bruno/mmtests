# ExtractXfsiothroughput.pm
package MMTests::ExtractXfsiothroughput;
use MMTests::SummariseMultiops;
use MMTests::Stat;
our @ISA = qw(MMTests::SummariseMultiops);
use strict;

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	$self->{_ModuleName} = "ExtractXfsiothroughput";
	$self->{_DataType}   = DataTypes::DATA_MBYTES_PER_SECOND;
	$self->{_FieldLength} = 12;

	$self->SUPER::initialise($reportDir, $testName);
}

sub extractReport() {
	my ($self, $reportDir, $reportName) = @_;
	my ($tm, $tput, $latency);
	my $iteration;
	my $testcase;
	my %testcases;
	$reportDir =~ s/xfsiothroughput/xfsio/;

	foreach my $file (<$reportDir/*-log.*>) {
		$testcase = $file;
		$testcase =~ s/.*\///;
		$testcase =~ s/-log.*//;

		$testcases{$testcase} = 1;

		open(INPUT, $file) || die("Failed to open $file\n");
		while (<INPUT>) {
			my $tput;

			if ($_ =~ /.*\(([0-9.]+) MiB\/sec.*/) {
				$tput = $1;
			} elsif ($_ =~ /.*\(([0-9.]+) GiB\/sec.*/) {
				$tput = $1 * 1024;
			} elsif ($_ =~ /.*\(([0-9.]+) KiB\/sec.*/) {
				$tput = $1 / 1024;
			} else {
				next;
			}

			$self->addData("$testcase-tput", ++$iteration, $tput);
		}
		close(INPUT);
	}

	my @operations;
	foreach $testcase (sort { $a <=> $b } keys %testcases) {
		push @operations, "$testcase-tput";
	}
	$self->{_Operations} = \@operations;
}

1;
