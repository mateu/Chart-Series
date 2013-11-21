use strictures 1;
package Chart::Series::Role::Data;
use Moose::Role;
use namespace::autoclean;
use List::Util qw/ min max /;

use Data::Dumper::Concise;

=head1 Synopsis

=head1 Attributes

=head2 plot_data

ArrayRef[ArrayRef[Num]] series (rows) of data to be plotted

=cut

has 'plot_data' => (
    is       => 'rw',
    isa      => 'ArrayRef[HashRef]',
    required => 1,
);
has 'min_range' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range',
);
has 'max_range' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range',
);
has 'min_range_padded' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range_padded',
);
has 'max_range_padded' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    builder => '_build_y_range_padded',
);
has 'range_ticks' => (
    is         => 'ro',
    isa        => 'ArrayRef[Int]',
    lazy_build => 1,
);
has 'number_of_datum' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);
has 'number_of_series' => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);
has 'x_values' => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    lazy_build => 1,
);

=head1 Methods

=cut

# Compute the max and min values for the y-axis (range).
sub _compute_range {
    my $self = shift;
    my @mins = map { min @{$_->{data}} } @{$self->plot_data};
    my $global_min = min @mins;
    my @maxes = map { max @{$_->{data}} } @{$self->plot_data};
    my $global_max = max @maxes;

    # WOTE: Find nearest factor of 10 above and below
    $global_max += 10 - ( $global_max % 10 );
    $global_min -= ( $global_min % 10 );
    return ( $global_min, $global_max );
}

sub _build_x_values {
    my $self = shift;
    
    return [1..$self->number_of_datum];
}

# Add just a touch of padding in case a value is right on the computed range.
# This keeps data from being cropped off in the graph.

sub _pad_range {
    my ( $self, $padding ) = @_;
    $padding ||= 2;
    return ( ( $self->min_range - $padding ), ( $self->max_range + $padding ) );
}

# Determine where the ticks for the y-axis will be based on the min/max values
# We coerce the ticks into integers for readability.

sub _build_range_ticks {
    my ($self) = @_;

    my $delta = $self->max_range - $self->min_range;
    my $tens  = int( $delta / 10 );
    my @ticks = ( int $self->min_range );
    for my $factor ( 1 .. $tens ) {
        push @ticks, ( ( int $self->min_range ) + ( $factor * 10 ) );
    }
    return \@ticks;
}

sub _build_y_range {
    my $self = shift;

    my ( $min_range, $max_range ) = $self->_compute_range;
    $self->min_range($min_range);
    $self->max_range($max_range);

    return;
}

sub _build_y_range_padded {
    my $self = shift;

    my ( $min_range_padded, $max_range_padded ) = $self->_pad_range;
    $self->min_range_padded($min_range_padded);
    $self->max_range_padded($max_range_padded);

    return;
}

sub _build_number_of_datum {
    my $self = shift;

    my $data = $self->plot_data;
    die "No data provided!" if (not defined $data->[0]->{data}->[0]);
    my $series_size;
    foreach my $series (@{$data}) {
        my $size = scalar @{$series->{data}};
        if ((defined $series_size) and ($size != $series_size)) {
            die "ERROR:  You have two series with different sizes: $size vs. $series_size\n";
        }
        else {
            $series_size = $size;
        }
    }
    return $series_size;
}

sub _build_number_of_series {
    return scalar @{shift->plot_data};
}

1