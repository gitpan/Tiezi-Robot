#!/usr/bin/perl 
# ABSTRACT: 下载帖子

use strict;
use warnings;
use utf8;

use Tiezi::Robot;

use Encode::Locale;
use Encode;
use Getopt::Std;

use vars qw/%opt/;

getopt( 'suftPFWUT', \%opt );

my $tiezi_url = $opt{u};

my $xs = Tiezi::Robot->new(
    site => $opt{s} || $tiezi_url, 
    type => $opt{t} || 'html', 
);

$xs->get_tiezi($tiezi_url, 
        'with_toc' => $opt{T} // 1, 
        'only_poster' => $opt{U} // undef, 
        'min_word_num' => $opt{W} // undef, 
        'max_page_num' => $opt{P} // undef, 
        'max_floor_num' => $opt{F} // undef,
);
