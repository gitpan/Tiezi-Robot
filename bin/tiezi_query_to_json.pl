#!/usr/bin/perl 
# ABSTRACT: 指定条件查询帖子信息，以JSON显示
=pod

=encoding utf8

=head1 USAGE

    #红晋江 四面无风版块ID为 153，在此版块进行查询

    tiezi_query_to_json.pl HJJ 153 贴子主题 迷侠

    tiezi_query_to_json.pl HJJ 153 主题贴内容 无风

    tiezi_query_to_json.pl HJJ 153 主题贴发贴人 定柔

    tiezi_query_to_json.pl HJJ 153 跟贴内容 无风

    tiezi_query_to_json.pl HJJ 153 跟贴发贴人 定柔

=cut

use strict;
use warnings;
use utf8;
use JSON;

use Tiezi::Robot;

use Encode::Locale;
use Encode;


my ($site,@args) = @ARGV;
$_ = decode( locale => $_ ) for @args;

my $tz = Tiezi::Robot->new();
$tz->set_site($site);

my $query_ref = $tz->get_query_ref(@args);
exit unless($query_ref);

my $query_json = encode_json $query_ref;
print $query_json;
