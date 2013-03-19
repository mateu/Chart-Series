use strictures 1;
package Chart::Series;
use Moose;
use namespace::autoclean;
use Chart::Clicker;
use Chart::Clicker::Decoration::Legend::Tabular;

with(
    'Chart::Series::Role::Clicker', 
    'Chart::Series::Role::Font', 
    'Chart::Series::Role::Color'
);

has 'chart' => (
    is         => 'ro',
    isa        => 'Chart::Clicker',
    lazy_build => 1,
);
has 'default_ctx' => (
    is         => 'ro',
    isa        => 'Chart::Clicker::Context',
    lazy_build => 1,
);

=head1 Methods

=head2 create_chart

This is the main method to call on an object to create a chart.

=cut

sub create_chart {
    my $self = shift;

    foreach my $index (0..$self->number_of_series-1) {
        my %series_data = %{$self->plot_data->[$index]};
        my $color  = $self->plot_colors->[$index];
        $self->dataset->add_to_series( $self->make_series(%series_data) );
        $self->color_allocator->add_to_colors( $color);
    }

    # Add freezing line when appropriate.
    my $freezing = 32;
    if ( $self->min_range_padded <= $freezing ) {
        $self->dataset->add_to_series( $self->constant_series($freezing) );
        $self->color_allocator->add_to_colors( $self->colors->{light_blue} );
    }

    # Add zero line when appropriate.
    my $zero = 0;
    if ( $self->min_range_padded <= $zero ) {
        $self->dataset->add_to_series( $self->constant_series($zero) );
        $self->color_allocator->add_to_colors( $self->colors->{light_blue} );
    }

    # Add 64 degree line when appropriate
    my $comfort = 64;
    if ( $self->max_range_padded >= $comfort ) {
        $self->dataset->add_to_series( $self->constant_series($comfort) );
        $self->color_allocator->add_to_colors( $self->colors->{light_blue} );
    }

    # Add 96 degree line when appropriate.
    my $hot = 96;
    if ( $self->max_range_padded >= $hot ) {
        $self->dataset->add_to_series( $self->constant_series($hot) );
        $self->color_allocator->add_to_colors( $self->colors->{light_blue} );
    }

    # add the dataset to the chart
    $self->chart->add_to_datasets( $self->dataset );

    # assign the color allocator to the chart
    $self->chart->color_allocator( $self->color_allocator );

    # write the chart to a file
    $self->chart->write_output( $self->chart_file );

}
sub _build_chart {
    my $self = shift;

    # Create the chart canvas
    my $chart = Chart::Clicker->new(
        width  => $self->chart_width,
        height => $self->chart_height,
        format => $self->chart_format,
    );

    # Title
    $chart->title->text( $self->title_text );
    $chart->title->font( $self->title_font );
    
    # Tufte influenced customizations (maximize data-to-ink)
    $chart->grid_over(1);
    $chart->legend->visible(1);
    $chart->legend->border->width(0);
    $chart->legend_position('south');
    $chart->plot->grid->show_range(0);
    $chart->plot->grid->show_domain(0);
    $chart->border->width(0);

    return $chart;
}

sub _build_default_ctx {
    my $self = shift;

    my $default_ctx = $self->chart->get_context('default');

    # Set number format of axis
    $default_ctx->domain_axis->format(
        sub { return $self->number_formatter->format_number(shift); } );
    $default_ctx->range_axis->format(
        sub { return $self->number_formatter->format_number(shift); } );
        
    # Set font of ticks
    $default_ctx->domain_axis->tick_font( $self->tick_font );
    $default_ctx->range_axis->tick_font( $self->tick_font );
    
    # The chart type is a "connect the dots" (line segments between data circles)
    $default_ctx->renderer( Chart::Clicker::Renderer::Line->new );
    $default_ctx->renderer->shape(
        Geometry::Primitive::Circle->new( { radius => 3, } ) );
    $default_ctx->renderer->brush->width(1);
    
    # Set ticks values for each axis
    $default_ctx->domain_axis->tick_values( $self->x_values );
    $default_ctx->range_axis->tick_values( $self->range_ticks );

    # Set max and min values for each axis.
    $default_ctx->domain_axis->range($self->domain);
    $default_ctx->range_axis->range($self->range);

    return $default_ctx;
}

=head2 BUILD

Here we do some initialization just after the object has been constructed.
Calling these builders here helped me defeat undef occuring from lazy dependencies.

=cut

sub BUILD {
    my $self = shift;
    
    $self->_build_y_range;
    $self->_build_y_range_padded;
    $self->_build_default_ctx;
}

__PACKAGE__->meta->make_immutable;
1