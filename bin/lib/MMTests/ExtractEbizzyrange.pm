# ExtractEbizzyrange.pm
package MMTests::ExtractEbizzyrange;
use MMTests::SummariseMultiops;
use MMTests::Stat;
our @ISA = qw(MMTests::SummariseMultiops);
use strict;

sub new() {
	my $class = shift;
	my $self = {
		_ModuleName  => "ExtractEbizzyrange",
		_DataType    => DataTypes::DATA_ACTIONS_PER_SECOND,
	};
	bless $self, $class;
	return $self;
}

sub extractReport() {
	my ($self, $reportDir, $reportName, $profile) = @_;

	$reportDir =~ s/ebizzyrange/ebizzy/;
	my @clients;
	my @files = <$reportDir/$profile/ebizzy-*-1.log>;
	foreach my $file (@files) {
		my @split = split /-/, $file;
		$split[-2] =~ s/.log//;
		push @clients, $split[-2];
	}
	@clients = sort { $a <=> $b } @clients;

	foreach my $client (@clients) {
		my $sample = 0;

		my @files = <$reportDir/$profile/ebizzy-$client-*>;
		foreach my $file (@files) {
			open(INPUT, $file) || die("Failed to open $file\n");
			while (<INPUT>) {
				my $line = $_;
				if ($line =~ /([0-9]*) records.*/) {
					my @elements = split(/\s+/, $line);
					shift @elements;
					shift @elements;
					$self->addData("spread-$client", $sample, calc_range(\@elements));
					$sample++;
				}
			}
			close INPUT;
		}
	}

	my @ops;
	foreach my $client (@clients) {
		push @ops, "spread-$client";
	}
	$self->{_Operations} = \@ops;
}

1;
