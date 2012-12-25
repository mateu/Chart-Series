use Chart::Series;
use Try::Tiny;
use Test::More;
use Data::Dumper::Concise;

my $plot_data = [
    [ 37, 28, 17, 22, 28, 25, 23 ],
    [ 18, 14, -4, 10, 18, 17, 15 ],
];

# Test basic flow
my $issue;
my $forecast;
try {
    $forecast = Chart::Series->new(
        plot_data   => $plot_data,
        chart_width => 280,
    );
    $forecast->create_chart;
}
catch {
    $issue = $_;
};
is( $issue, undef, 'Canonical work flow' );

SKIP: 
{
    eval 'use Image::Imlib2';
    skip( 'because Image::Imlib2 is required to test output image', 1 ) if $@;
        
    # Test we can read the image, its width in particular
    my $image = Image::Imlib2->load($forecast->chart_file);
    is($image->width, 280, 'chart width');

}

done_testing();
