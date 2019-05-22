# ExtractNetperfmulti.pm
package MMTests::ExtractNetperfmulti;
use MMTests::SummariseMultiops;
use MMTests::Stat;
our @ISA = qw(MMTests::SummariseMultiops);
use strict;

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	$self->{_ModuleName} = "ExtractNetperfmulti";
	$self->{_DataType}   = DataTypes::DATA_MBITS_PER_SECOND;
	$self->{_PlotType}   = "client-errorlines";

	$self->SUPER::initialise($reportDir, $testName);
}

sub extractReport() {
	my ($self, $reportDir, $reportName) = @_;
	my ($tm, $tput, $latency);

	open (INPUT, "$reportDir/protocols");
	my $protocol = <INPUT>;
	chomp($protocol);
	close(INPUT);

	my @clients;
	my @files = <$reportDir/$protocol-*.1>;
	foreach my $file (@files) {
		my @elements = split (/-/, $file);
		my $client = $elements[-1];
		$client =~ s/\.1$//;
		push @clients, $client;
	}
	@clients = sort {$a <=> $b} @clients;

	my $loss;
	foreach my $client (@clients) {
		my $iteration = 0;

		foreach my $file (<$reportDir/$protocol-$client.*>) {
			my $send_tput = 0;
			my $recv_tput = 0;

			open(INPUT, $file) || die("Failed to open $file\n");
			while (<INPUT>) {
				my @elements = split(/\s+/, $_);
				if ($_ =~ /[a-zA-Z]/ || $_ =~ /^$/) {
					next;
				}
				my $line = $_;
				$line =~ s/^\s+//;
				my @elements = split(/\s+/, $line);
				if ($protocol ne "UDP_STREAM") {
					if ($#elements > 3) {
						$send_tput += $elements[-1];
					}
				} else {
					if ($#elements == 5) {
						$send_tput += $elements[-1];
					}
					if ($#elements == 3) {
						$recv_tput += $elements[-1];
					}
				}
			}
			close(INPUT);

			if ($protocol ne "UDP_STREAM") {
				$self->addData($client, ++$iteration, $send_tput);
			} else {
				$self->addData("send-$client", ++$iteration, $send_tput);
				$self->addData("recv-$client", ++$iteration, $recv_tput);
				$self->addData("loss-$client", ++$iteration, $send_tput - $recv_tput );
				if (($send_tput - $recv_tput) > ($send_tput / 10)) {
					$loss++;
				}
			}
		}
	}
	if ($protocol ne "UDP_STREAM") {
		$self->{_Operations} = \@clients;
	} else {
		my @ops;
		my @directions = ("send", "recv");
		if ($loss) {
			push @directions, "loss";
		}
		foreach my $direction (@directions) {
			foreach my $client (@clients) {
				push @ops, "$direction-$client";
			}
		}
		$self->{_Operations} = \@ops;
	}
}

1;
