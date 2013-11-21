#use Chart::Weather::History::Snow;
use Chart::Series;
use LWP::Simple;
use HTML::TableExtract;
use Test::More;
use List::Util qw/min max/;

use DDP colored => 0;
use Data::Dumper::Concise;

my $sites = {
    blacktail => {
        site => 1144,
        state => MT,
    },
    saddle => {
        site => 727,
        state => MT,
    },
    stuart => {
        site => 901,
        state => MT,
    },
    lolo => {
        site => 588,
        state => ID,
    },
    hoodoo => {
        site => 530,
        state => MT,
    },
    hawkins => {
        site => 516,
        state => ID,
    },
    lookout => {
        site => 594,
        state => ID,
    },
    banfield => {
        site => 311,
        state => MT,
    },
    bigsky => {
        site => 590,
        state => MT,
    },
    brackett => {
        site => 365,
        state => MT,
    },
    targhee => {
        site => 1082,
        state => WY,
    },
    stevens_pass => {
        site => 791,
        state => WA,
    },
};

main();

ok(1);
done_testing;

sub main {
    foreach my $site_name (keys %{$sites}) {
        # Be nice to the site, don't hit it so hard
        sleep(rand(2) + 1);
        create_snotel_chart($site_name);
        #last;
    }
}

sub delta_24 {
    my @data = @_;

    my $last = $data[-1];
    my ($temp_24, $depth_24) = find_last_24($last->{date}, $last->{time}, @data);
    return ('n/a', 'n/a') if (not defined $temp_24);
    return ($last->{temp} - $temp_24, $last->{depth} - $depth_24);
}

sub find_last_24 {
    my($date, $time, @data) = @_;

    my ($year, $month, $day) = split /-/, $date;
    my ($hour, $minute) = $time =~ m/(\d{2})(\d{2})/;
    use DateTime;
    my $yesterday = DateTime->new(
        year => $year, 
        month => $month, 
        day => $day,
        hour => $hour,
        minute => $minute,
    )->add(days => -1);
    my $hms = $yesterday->hms;
    my ($hh, $mm) = $hms =~ m/(\d{2}):(\d{2}):\d{2}/;
    my $ahi = { date => $yesterday->ymd, 'time' => $hh . $mm };
    my %result = get_data_for(date => $yesterday->ymd, 'time' => $hh . $mm, data => \@data);
    return @result{qw/ temp depth /};
}

sub get_data_for {
    my %args = @_;

    my $date= $args{date};
    my $time= $args{'time'};
    my $data= $args{data};
    my ($temp, $depth);
    foreach my $datum (@{$data}) {
        if (($datum->{date} eq $date) and ($datum->{'time'} eq $time)) {
            $temp = $datum->{temp};
            $depth = $datum->{depth};
        }
    }
    return (temp => $temp, depth => $depth); 
}

sub create_snotel_chart {
    my ($site_name) = @_; 

    $site_name ||= 'saddle';
    my $days = 7;
    warn "getting data for site: $site_name\n";
    my @data = get_data(site_name => $site_name, days => $days);
    if (not defined $data[0]) {
        warn "No data for $site_name\n";
        return;
    }
    my $last_24_hours;
    my ($delta_temp, $delta_depth) = delta_24(@data);
    warn "delta_temp: $delta_temp, delta_depth: $delta_depth";
    my $depths = [ map { $_->{depth} } @data ];
    my $temps  = [ map { $_->{temp} } @data ];
    my $times  = [ map { $_->{time} } @data ];
    my $dates  = [ map { $_->{date} } @data ];
    my $title_text = "${site_name} - ${days}-day snow/temp history"; 
    my $snotel_chart_file = '/tmp/' . $site_name . "_${days}days.png";
    my $snotel_chart = Chart::Series->new(
        plot_data   => [
            { 
                name => 'Temp',
                data => $temps,
            },
            {
                name => 'Depth',
                data => $depths
            }
        ],
        chart_width => 1187,
        chart_height => 667,
        title_text => $title_text,
        chart_file => $snotel_chart_file,
    );
    # Blank all but first and last dates
    my @timestamps;
    my @dates = @{$dates};
    for my $i (0..$#dates) {
        my $timestamp = '';
        if ($i == 0 or $i == $#dates) {
            my ($hour, $minute) = $times->[$i] =~ m/(\d\d)(\d\d)/;
            $timestamp = $dates->[$i]. ' ' . "${hour}:${minute}" ;
        }
        push @timestamps, $timestamp;
    }
        $snotel_chart->chart->legend(Chart::Clicker::Decoration::Legend::Tabular->new(
        header => [ ('', 'Min', 'Max', '24hr change') ],
        data => [
            [ min(@{$temps}), max(@{$temps}), $delta_temp], 
            [ min(@{$depths}), max(@{$depths}), $delta_depth], 
        ]
    ));
    $snotel_chart->default_ctx->domain_axis->tick_labels( \@timestamps );
    warn "creating chart for site: $site_name";
    $snotel_chart->create_chart;
}

sub get_data {
    my %args = @_;

    my ($site_name, $state, $days) = @args{qw/site_name state days/};
    # Set of defaults if not passed a values
    $site_name ||= 'saddle';
    $days      ||= 5;
    $state     ||= 'MT';
    
    my $host   = 'http://www.wcc.nrcs.usda.gov/';
    my $script = 'nwcc/sntl-datarpt.jsp';
    my $site   = $sites->{$site_name}->{site};

    my $snotel_url =
      "${host}${script}?site=${site}\&days=${days}\&state=${state}";
    my $snotel_html = get $snotel_url;
    my $te =
      HTML::TableExtract->new(headers => [ 'Date', 'Time', 'Depth', 'Current' ],
      );
    $te->parse($snotel_html);
    my @data;

    foreach my $table ($te->tables) {
        foreach my $row ($table->rows) {
            my $time = $row->[1];
            # skip non-data rows
            next unless ($time and ($time =~ /\d{4}/));
            my $date = $row->[0];
            $date =~ s/\n//g;
            my $depth = $row->[2];
            $depth =~ s/\n//g;
            # Discard bad data which is indicated by a depth of -99.9
            next if (($depth == -99.9) or ($depth eq 'M'));
            my $temp = $row->[3];
            $temp =~ s/\n//g;
            next if ($temp == -99.9);
            print "$date - $time - $depth - $temp\n";
            push @data,
              { date => $date, time => $time, depth => $depth, temp => $temp };
        }
    }
    return @data;
}

__END__

my $fake_data = [
    {
        date  => '11-24-2012',
        time  => '0000',
        depth => 6.0,
        temp  => 36.0,
    },
    {
        date  => '11-24-2012',
        time  => '0300',
        depth => 7.0,
        temp  => 31.0,
    },
    {
        date  => '11-24-2012',
        time  => '0600',
        depth => 9.0,
        temp  => 28.0,
    }
];

# Reference site for finding snotels
my $form_url = "http://www.wcc.nrcs.usda.gov/cgibin/sdr-all.pl?state=${state}";
