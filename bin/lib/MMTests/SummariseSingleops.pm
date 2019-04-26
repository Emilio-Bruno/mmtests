# SummariseSingleops.pm
package MMTests::SummariseSingleops;
use MMTests::Extract;
use MMTests::Summarise;
use MMTests::Stat;
our @ISA = qw(MMTests::Summarise);
use strict;

sub new() {
	my $class = shift;
	my $self = {
		_ModuleName  => "SummariseSingleops",
	};
	bless $self, $class;
	return $self;
}

sub printPlot() {
	my ($self, $subHeading) = @_;

	$self->sortResults();
	if ($subHeading eq "") {
		$self->{_PrintHandler}->printRow($self->{_ResultData}, $self->{_FieldLength}, $self->{_FieldFormat});
	} else {
		my @filteredData;
		foreach my $row (@{$self->{_ResultData}}) {
			if ($self->{_ClientSubheading} == 1) {
				if (@{$row}[0] =~ /.*-$subHeading$/) {
					if ($self->{_PlotStripSubheading}) {
						@{$row}[0] =~ s/-$subHeading$//;
					}
					push @filteredData, $row;
				}
			} else {
				if (@{$row}[0] =~ /^$subHeading.*/) {
					if ($self->{_PlotStripSubheading}) {
						@{$row}[0] =~ s/^$subHeading-//;
					}
					push @filteredData, $row;
				}
			}
		}
		$self->{_PrintHandler}->printRow(\@filteredData, $self->{_FieldLength}, $self->{_FieldFormat});
	}
}

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	my $opName = "Ops";
	my $fieldLength = 12;
	if (defined $self->{_FieldLength}) {
		$fieldLength = $self->{_FieldLength};
	}
	if (defined $self->{_Opname}) {
		$opName = $self->{_Opname};
	} else {
		$self->{_Opname} = "Ops";
	}

	$self->SUPER::initialise($reportDir, $testName);

	$self->{_FieldFormat} = [ "%-${fieldLength}s", "", "%${fieldLength}.2f" ];
	$self->{_FieldHeaders} = [ "Type", $self->{_Opname} ? $self->{_Opname} : "Ops" ];

	$self->{_SummaryLength} = 16;
	$self->{_SummaryHeaders} = [ $self->{_Opname} ? $self->{_Opname} : "Ops"  ];
	$self->{_SummariseColumn} = 2;
	$self->{_RatioPreferred} = "Higher";

	if ($self->{_DataType} == DataTypes::DATA_TIME_SECONDS ||
	    $self->{_DataType} == DataTypes::DATA_TIME_NSECONDS ||
	    $self->{_DataType} == DataTypes::DATA_TIME_MSECONDS ||
	    $self->{_DataType} == DataTypes::DATA_TIME_USECONDS ||
	    $self->{_DataType} == DataTypes::DATA_TIME_CYCLES ||
	    $self->{_DataType} == DataTypes::DATA_BAD_ACTIONS) {
		$self->{_RatioPreferred} = "Lower";
		$self->{_CompareOp} = "pndiff";
	}
	if ($self->{_DataType} == DataTypes::DATA_ACTIONS ||
	    $self->{_DataType} == DataTypes::DATA_ACTIONS_PER_SECOND ||
	    $self->{_DataType} == DataTypes::DATA_ACTIONS_PER_MINUTE ||
	    $self->{_DataType} == DataTypes::DATA_OPS_PER_SECOND ||
	    $self->{_DataType} == DataTypes::DATA_OPS_PER_MINUTE ||
	    $self->{_DataType} == DataTypes::DATA_KBYTES_PER_SECOND ||
	    $self->{_DataType} == DataTypes::DATA_MBYTES_PER_SECOND ||
	    $self->{_DataType} == DataTypes::DATA_MBITS_PER_SECOND ||
	    $self->{_DataType} == DataTypes::DATA_TRANS_PER_SECOND ||
	    $self->{_DataType} == DataTypes::DATA_TRANS_PER_MINUTE ||
	    $self->{_DataType} == DataTypes::DATA_SUCCESS_PERCENT  ||
	    $self->{_DataType} == DataTypes::DATA_RATIO_SPEEDUP) {
		$self->{_RatioPreferred} = "Higher";
		$self->{_CompareOp} = "pdiff";
	}

	$self->{_TestName} = $testName;
}

sub extractSummary() {
	my ($self, $subHeading) = @_;

	$self->{_SummaryData} = {};
	for my $row (@{$self->{_ResultData}}) {
		my $op = $row->[0];
		my $value = $row->[2];
		$self->{_SummaryData}->{$op} = [ $value ];
	}
	my @ops = map {$_ -> [0]} @{$self->{_ResultData}};
	$self->{_Operations} = \@ops;
	return 1;
}

sub extractRatioSummary() {
	my ($self, $subHeading) = @_;
	my %data = %{$self->dataByOperation()};
	my @ops = map {$_ -> [0]} @{$self->{_ResultData}};
	my @ratioops;

	if (!defined $self->{_SingleType}) {
		print "Unsupported\n";
		return 1;
	}

	$self->{_Operations} = \@ops;
	@ratioops = $self->ratioSummaryOps($subHeading);

	$self->{_SummaryHeaders} = [ "Ratio" ];

	my %summaryData;
	foreach my $op (@ratioops) {
		foreach my $rowLine (@{$data{$op}}) {
			$summaryData{$op} = [$rowLine->[1]];
		}
	}
	$self->{_SummaryData} = \%summaryData;

	return 1;
}

sub printReport() {
	my ($self) = @_;
	$self->{_PrintHandler}->printRow($self->{_ResultData}, $self->{_FieldLength}, $self->{_FieldFormat});
}

1;
