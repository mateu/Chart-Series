use strictures 1;
package Chart::Series::Role::Font;
use Graphics::Primitive::Font;
use Moose::Role;

has 'title_font' => (
    is        => 'rw',
    isa       => 'Graphics::Primitive::Font',
    'default' => sub {
        Graphics::Primitive::Font->new(
            {
                family         => 'Trebuchet',
                size           => 11,
                antialias_mode => 'subpixel',
                hint_style     => 'medium',

            }
        );
    },
);
has 'tick_font' => (
    is        => 'rw',
    isa       => 'Graphics::Primitive::Font',
    'default' => sub {
        Graphics::Primitive::Font->new(
            {
                family         => 'Trebuchet',
                size           => 11,
                antialias_mode => 'subpixel',
                hint_style     => 'medium',

            }
        );
    },
);

1