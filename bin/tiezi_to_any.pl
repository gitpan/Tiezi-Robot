#!/usr/bin/perl 

=pod

=encoding utf8

=head1 DESC

    TERM下面选择下载贴子

=head1 EXAMPLE

    tiezi_to_any.pl -b "http://bbs.jjwxc.net/showmsg.php?board=153&id=57" -m 1 -t HTML

    tiezi_to_any.pl -s HJJ -b 153 -q 主题贴发贴人 -v 定柔 -m 1
    
=head1 USAGE

    tiezi_to_any.pl -b [board_url] -m [select_menu_or_not] -t [packer_type]

    tiezi_to_any.pl -s [site] -b [board_url/board_num] -q [query_keyword] -v [query_value] -m [select_menu_or_not] -t [packer_type]

=head1 OPTIONS

    -b : 版块URL

    -s : 指定查询的站点
    -q : 查询的类型
    -v : 查询的关键字

    -m : 是否输出贴子选择菜单

    -t : 贴子保存类型，例如HTML/TXT

=cut

use strict;
use warnings;
use utf8;

use Encode::Locale;
use Encode;
use Getopt::Std;
use Tiezi::Robot;

$| = 1;

my %opt;
getopt( 'bsqvmt', \%opt );

my $xs = Tiezi::Robot->new();
$xs->set_packer( $opt{t} || 'HTML' );
$xs->set_parser( $opt{s} || $opt{b} );

my $tiezis_ref;

if ( $opt{q} ) {
    my $query_data = {
        type    => decode( locale => $opt{q} ),
        keyword => decode( locale => $opt{v} ),
    };
    $query_data->{board} = decode( locale => $opt{b} ) if ( $opt{b} );
    my $query_ref = $xs->get_query_ref( $query_data, \&return_sub );
    $tiezis_ref = $query_ref->{tiezis};
} ## end if ( $opt{q} )
elsif ( $opt{b} ) {
    my $board_ref = $xs->get_board_ref( $opt{b}, \&return_sub );
    $tiezis_ref = $board_ref->{tiezis};
}

my $select = $opt{m} ? $xs->select_tiezi($tiezis_ref) : $tiezis_ref;
for my $r (@$select) {
    my $u = $r->{url};
    next unless ($u);
    $xs->get_tiezi($u);
}

sub return_sub {
    my ($r) = @_;
    return 1 if ( $r->{tiezi_num} > 20 );
}
