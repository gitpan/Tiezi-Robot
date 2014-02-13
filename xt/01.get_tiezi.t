#!/usr/bin/perl
use utf8;
use Tiezi::Robot;
use Test::More ;
use Data::Dump qw/dump/;
use Encode;


my $tz = Tiezi::Robot->new( site => 'HJJ', type=> 'html');

my $url = 'http://bbs.jjwxc.net/showmsg.php?board=3&boardpagemsg=1&id=703914';

my $r = $tz->get_tiezi($url, 
    #output => 'tz.html', 
    output_scalar => 1, 
    #output_file => 1, 
    with_toc => 1, 
    min_word_num => 100, 
    #only_poster => 1, 
    #max_floor_num => 3, 
    #max_page_num => 2, 
);

dump($r);

done_testing;
