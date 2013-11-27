#!/usr/bin/perl 
# ABSTRACT: 下载帖子，存成txt

use strict;
use warnings;
use utf8;

use Tiezi::Robot;

use Encode::Locale;
use Encode;
use Getopt::Std;

use vars qw/%OPT/;


$|=1;

getopt( 'sufPFWUT', \%OPT );


my $tiezi_url = $OPT{u};

print "\rget tiezi to txt : $tiezi_url";

my $xs = Tiezi::Robot->new();
$xs->set_parser($OPT{s} || $tiezi_url) ;
$xs->set_packer('TXT');
my $o = { 
        'with_toc' => $OPT{T} // 1, 
        'only_poster' => $OPT{U} // undef, 
        'min_word_num' => $OPT{W} // undef, 
        'max_page_num' => $OPT{P} // undef, 
        'max_floor_num' => $OPT{F} // undef,
};
$xs->get_tiezi($tiezi_url, $o);
