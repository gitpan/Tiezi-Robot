#!/usr/bin/perl 
# ABSTRACT: 指定条件查询帖子信息，以JSON显示
=pod

=encoding utf8

=head1 USAGE

    #在红晋江 第 153 版块 查询主题 为 迷侠 的贴子
    tiezi_query_to_json.pl HJJ 153 贴子主题 迷侠

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
