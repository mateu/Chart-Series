use Chart::Series;
use Try::Tiny;
use Test::More;
use Data::Dumper::Concise;

my $plot_data = [
    [ 37, 28, 17, 22, 28, 25, 23 ],
    [ 18, 14, -4, 10, 18, 17, 15 ],
    [ 48, 54, 44, 50, 68, 77, 75 ],
];

# Test basic flow
my $issue;
my $forecast;
my ($width, $height) = (640, 480);
try {
    $forecast = Chart::Series->new(
        plot_data   => $plot_data,
        chart_width => $width,
        chart_height => $height,
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
    is($image->width, $width, 'chart width');

}

done_testing();
