use strictures 1;
package Chart::Series::Role::Clicker;
use Moose::Role;
use namespace::autoclean;
use MooseX::Types::Path::Class;

use Chart::Clicker;
use Chart::Clicker::Data::Range;
use Chart::Clicker::Data::Series;
use Chart::Clicker::Data::DataSet;
use Geometry::Primitive::Circle;
use Number::Format;
use List::Util qw/ min max /;
use Path::Class qw/ file /;

with('Chart::Series::Role::Data');

use Data::Dumper::Concise;

=head1 Attributes

=head2 chart_file

Where you want to write out the chart image.

    Default: /tmp/temperature-forecast.png' on *nix

=head2 chart_width

Chart dimension in pixels

    Default: 240

=head2 chart_height

Chart dimension in pixels

    Default: 160

=head2 chart_format

Format of the chart image

    Default: png
    
=head2 title_text

The text to title the chart with.

    Default: Temperature Forecast

=cut

has 'chart_file' => (
    is        => 'ro',
    isa       => 'Path::Class::File',
    required  => 1,
    coerce    => 1,
    'default' => sub {  Path::Class::File->new(File::Spec->tmpdir, 'temperature-forecast.png') },
);
has 'chart_format' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'png' },
);

has 'chart_width' => (
    is      => 'ro',
    isa     => 'Int',
    default => 240,
);
has 'chart_height' => (
    is      => 'ro',
    isa     => 'Int',
    default => 160,
);
has 'title_text' => (
    is        => 'rw',
    isa       => 'Str',
    'default' => sub {
        my $self = shift;
        return $self->number_of_datum . ' point series';
    },
);

has 'number_formatter' => (
    is        => 'ro',
    isa       => 'Number::Format',
    'default' => sub { Number::Format->new },
);
has 'dataset' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Data::DataSet',
    'default' => sub {
        Chart::Clicker::Data::DataSet->new;
    },
);
has 'domain' => (
    is         => 'ro',
    isa        => 'Chart::Clicker::Data::Range',
    lazy_build => 1,
);
has 'range' => (
    is         => 'ro',
    isa        => 'Chart::Clicker::Data::Range',
    lazy_build => 1,
);

=head1 Methods

=cut 

# Compute the max and min values for the y-axis (range).
sub _build_domain {
    my $self = shift;

    my $fudge_factor = 0.25;
    return Chart::Clicker::Data::Range->new(
        {
            lower => (1 - $fudge_factor),
            upper => ($self->number_of_datum + $fudge_factor),
        }
    );
}

sub _build_range {
    my $self = shift;

    return Chart::Clicker::Data::Range->new(
        {
            lower => $self->min_range_padded,
            upper => $self->max_range_padded,
        }
    );
}

=head2 constant series

series of a repeat value - useful for plotting noteworthy lines (e.g. 32 degrees)

=cut

sub constant_series {
    my ($self, $height) = @_;
        Chart::Clicker::Data::Series->new(
            keys =>  $self->x_values,
            values => [ ($height) x $self->number_of_datum ],
        );
}

=head2 make_series

Given a list of points, return a Chart Clicker Data Series

=cut

sub make_series {
    my ($self, $data_points) = @_;

    return Chart::Clicker::Data::Series->new(
        keys   => $self->x_values,
        values => $data_points,
    );
}

1