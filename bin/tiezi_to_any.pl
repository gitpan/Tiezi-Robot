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


    -M : 列表取 top n 页的贴子

    -N : 列表取 top n 个贴子

    -P : 贴子内容取 top n 页

    -F : 贴子取 top n 楼

    -W : 跟贴至少要 n 个字

    -U : 只看楼主(默认是取出所有楼层，不只楼主)

    -T : 生成的贴子不加楼层目录(默认是加楼层目录)

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
getopt( 'bsqvmtPFWUT', \%opt );

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
    my $query_ref = $xs->get_query_ref( $query_data, {
            'max_page_num' => $opt{M}, 
            'max_tiezi_num' => $opt{N}, 
        });
    $tiezis_ref = $query_ref->{tiezis};
} ## end if ( $opt{q} )
elsif ( $opt{b} ) {
    my $board_ref = $xs->get_board_ref( $opt{b}, {
            'max_page_num' => $opt{M}, 
            'max_tiezi_num' => $opt{N}, 
        });
    $tiezis_ref = $board_ref->{tiezis};
}

my $select = $opt{m} ? $xs->select_tiezi($tiezis_ref) : $tiezis_ref;
for my $r (@$select) {
    my $u = $r->{url};
    next unless ($u);
    print "$u\n";
    $xs->get_tiezi($u, { 
        'with_toc' => $opt{T} // 1, 
        'only_poster' => $opt{U} // undef, 
        'min_word_num' => $opt{W} // undef, 
        'max_page_num' => $opt{P} // undef, 
        'max_floor_num' => $opt{F} // undef,
    });
}

sub return_sub {
    my ($r) = @_;
    #return 1 if ( $r->{tiezi_num} > 20 );
    return;
}
