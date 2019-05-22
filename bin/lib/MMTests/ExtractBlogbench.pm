# ExtractBlogbench.pm
package MMTests::ExtractBlogbench;
use MMTests::SummariseMultiops;
use MMTests::Stat;
our @ISA = qw(MMTests::SummariseMultiops);
use strict;

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	$self->{_ModuleName} = "ExtractBlogbench";
	$self->{_DataType}   = DataTypes::DATA_ACTIONS;
	$self->{_PlotType}   = "operation-candlesticks";
	$self->SUPER::initialise($reportDir, $testName);
}

sub extractReport() {
	my ($self, $reportDir) = @_;
	my $recent = 0;

	my @files = <$reportDir/blogbench-*.log>;
	my $iteration = 1;
	foreach my $file (@files) {
		open(INPUT, $file) || die("Failed to open $file\n");
		while (<INPUT>) {
			my $line = $_;
			next if $line !~ /^Final score/;
			my @elements = split(/\s+/, $line);

			$self->addData("ReadScore", $iteration, $elements[-1]) if $line =~ /reads/;
			$self->addData("WriteScore", $iteration, $elements[-1]) if $line =~ /writes/;

		}
		close INPUT;
	}

	$self->{_Operations} = [ "ReadScore", "WriteScore" ];
}

1;
