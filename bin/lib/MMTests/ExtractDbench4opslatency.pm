# ExtractDbench4.pm
package MMTests::ExtractDbench4opslatency;
use MMTests::SummariseSingleops;
use MMTests::Stat;
our @ISA = qw(MMTests::SummariseSingleops);
use strict;

sub new() {
	my $class = shift;
	my $self = {
		_ModuleName  => "ExtractDbench4opslatency",
		_DataType    => DataTypes::DATA_TIME_MSECONDS,
	};
	bless $self, $class;
	return $self;
}

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	$self->{_Opname} = "latency";
	$self->SUPER::initialise($reportDir, $testName);
}

sub extractReport() {
	my ($self, $reportDir, $reportName) = @_;
	my ($tm, $tput, $latency);
	my $readingOperations = 0;
	my @clients;
	$reportDir =~ s/4opslatency/4/;
	my %dbench_ops = ("NTCreateX"	=> 1, "Close"	=> 1, "Rename"	=> 1,
			  "Unlink"	=> 1, "Deltree"	=> 1, "Mkdir"	=> 1,
			  "Qpathinfo"	=> 1, "WriteX"	=> 1, "ReadX"	=> 1,
			  "Qfileinfo"	=> 1, "Qfsinfo"	=> 1, "Flush"	=> 1,
			  "Sfileinfo"	=> 1, "LockX"	=> 1, "UnlockX"	=> 1,
			  "Find"	=> 1);

	my @files = <$reportDir/dbench-*.log*>;
	if ($files[0] eq "") {
		@files = <$reportDir/tbench-*.log*>;
	}
	foreach my $file (@files) {
		my @split = split /-/, $file;
		$split[-1] =~ s/.log.*//;
		push @clients, $split[-1];
	}
	@clients = sort { $a <=> $b } @clients;

	my $index = 1;
	foreach my $header ("count", "avg", "max") {
		$index++;
		foreach my $client (@clients) {
			my $file = "$reportDir/dbench-$client.log";
			if (! -e $file) {
				$file = "$reportDir/dbench-$client.log.gz";
			}
			if (! -e $file) {
				$file = "$reportDir/tbench-$client.log";
			}
			if (! -e $file) {
				$file = "$reportDir/tbench-$client.log.gz";
			}
			if ($file =~ /.*\.gz$/) {
				open(INPUT, "gunzip -c $file|") || die("Failed to open $file\n");
			} else {
				open(INPUT, $file) || die("Failed to open $file\n");
			}
			while (<INPUT>) {
				my $line = $_;
				if ($line =~ /Operation/) {
					$readingOperations = 1;
				}

				if ($readingOperations != 1) {
					next;
				}

				my @elements = split(/\s+/, $line);
				if ($dbench_ops{$elements[1]} == 1) {
					$self->addData("$header-$elements[1]-$client", 0, $elements[$index]);
				}
			}
			close INPUT;
		}
	}

}

1;
