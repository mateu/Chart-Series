use strictures 1;
package Chart::Series::Role::Color;
use Moose::Role;
use Graphics::Color::RGB;
use Chart::Clicker::Drawing::ColorAllocator;

#requires('number_of_series');

has 'plot_colors' => (
    is       => 'rw',
    isa      => 'ArrayRef[Graphics::Color::RGB]',
    lazy_build => 1,
);
has 'colors' => (
    is         => 'ro',
    isa        => 'HashRef[Graphics::Color::RGB]',
    lazy_build => 1,
);
has 'color_allocator' => (
    is        => 'ro',
    isa       => 'Chart::Clicker::Drawing::ColorAllocator',
    'default' => sub {
        Chart::Clicker::Drawing::ColorAllocator->new;
    },
);

# Default having red and blue on the first two colors
sub _build_plot_colors {
    my ($self, ) = @_;

    my $size = $self->number_of_series;
    # We have two fixed colors by default, red followed by blue
    my $number_of_random_colors = $size - 2;
    my @random_colors;
    if ($number_of_random_colors > 0) {
        push @random_colors, $self->random_color() for (1..$number_of_random_colors);
    }
    my @colors = ($self->colors->{red}, $self->colors->{blue}, @random_colors);
    return \@colors;
}

=head2 random_color

Get a random color.

=cut

sub random_color {
    return Graphics::Color::RGB->new({
        red   => rand(1.0),
        green => rand(1.0),
        blue  => rand(1.0),
        alpha => .8
    });
}

sub _build_colors {
    my $self = shift;

    {
        red => Graphics::Color::RGB->new(
            {
                red   => .75,
                green => 0,
                blue  => 0,
                alpha => .8
            }
        ),
        blue => Graphics::Color::RGB->new(
            {
                red   => 0,
                green => 0,
                blue  => .75,
                alpha => .8
            }
        ),
        light_blue => Graphics::Color::RGB->new(
            {
                red   => 0,
                green => 0,
                blue  => .95,
                alpha => .16
            }
        ),
    };
}

1