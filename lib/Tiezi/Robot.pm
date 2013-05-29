# ABSTRACT: 贴子下载器
=pod

=encoding utf8

=head1 NAME

Tiezi::Robot - 贴子下载器

=head2 支持站点

=item *

HJJ : 红晋江 http://bbs.jjwxc.net

=back

=head1 EXAMPLE

    #取出指定贴子，只看楼主，且跟贴内容不能少于100字 

    tiezi_to_html.pl -u "http://bbs.jjwxc.net/showmsg.php?board=153&id=57" -U 1 -C 100

    #按版块取出贴子URL信息，超出50贴或超出3页就停止

    tiezi_to_any.pl -b "http://bbs.jjwxc.net/board.php?board=153&page=1" -t 50 -p 3 
    
    #在红晋江 第 153 版块 查询主题 为 迷侠 的贴子

    tiezi_to_any.pl -s HJJ -b 153 -q 贴子主题 -v 迷侠 -m 1
    
=cut

use strict;
use warnings;
 
package Tiezi::Robot;

our $VERSION=0.10;

use utf8;

use Encode;
use Moo;
use Novel::Robot::Browser;
use Tiezi::Robot::Parser; 
use Tiezi::Robot::Packer; 
use Term::Menus;

has browser => ( is => 'rw', 
    default => sub {
        my ($self) = @_;
        my $browser = new Novel::Robot::Browser();
        return $browser;
    },
);

has parser_base => (
    is      => 'ro',
    default => sub {
        my ($self) = @_;
        my $parser_base = new Tiezi::Robot::Parser();
        return $parser_base;
    },
);

has parser => ( is => 'rw', );

has packer_base => (
    is      => 'ro',
    default => sub {
        my ($self) = @_;
        my $packer_base = new Tiezi::Robot::Packer();
        return $packer_base;
    },
);

has packer => ( is => 'rw', );

sub set_parser {
    my ( $self, $s, $o ) = @_;

    $self->{parser} = $self->{parser_base}->init_parser( $s, $o );

} ## end sub set_parser

sub set_packer {
    my ( $self, $s, $o ) = @_;

    $self->{packer} = $self->{packer_base}->init_packer( $s, $o );

} ## end sub set_packer

sub get_tiezi {
    my ( $self, $tz_url, $o ) = @_; 
    $o ||= {}; 

    my $tz = $self->get_tiezi_ref($tz_url);
    return unless ($tz and $tz->{topic} and $tz->{topic}{name} and $tz->{topic}{title});
    $tz->{topic}{url} = $tz_url;
    
    #选取指定楼层
    if($o->{skip_floor}){
        for my $f (@{$tz->{floors}}){
            $f->{skip} = $o->{skip_floor}->($tz, $f);
        }
    }

    $self->{packer}->open_packer($tz);

    $self->{packer}->format_before_toc($tz);
    unless($o->{skip_toc}){
        $self->{packer}->format_toc($tz);
    }
    $self->{packer}->format_after_toc($tz);

    $self->{packer}->format_before_floor($tz);
    for my $i (0 .. $#{$tz->{floors}}){
        my $d = $tz->{floors}[$i];
        next unless ($d);

        $self->{packer}->format_floor( $d, $i+1 );
    } ## end for my $i ( 1 .. $tz...)
    $self->{packer}->format_after_floor($tz);

    $self->{packer}->close_packer();
}

sub get_tiezi_ref {
    my ( $self, $url ) = @_;
    
    my $html_ref = $self->{browser}->get_url_ref( $url );
    return unless $html_ref;
    
    my %result;
    
    $result{topic} = $self->{parser}->parse_tiezi_topic($html_ref);
    $result{floors}          = $self->{parser}->parse_tiezi_floors($html_ref);
    my $result_urls_ref = $self->{parser}->parse_tiezi_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    for my $u (@$result_urls_ref) {
        my $h = $self->{browser}->get_url_ref($u);
        my $r = $self->{parser}->parse_tiezi_floors($h);
        push @{$result{floors}} , @$r;
    }
    
    $_->{title} ||= '' for(@{$result{floors}});

    return \%result;
} ## end sub get_tiezi_ref

sub get_board_ref {
    my ( $self, $url , $return_sub ) = @_;
    
    my $html_ref = $self->{browser}->get_url_ref( $url );
    print "board : $url\n";
    return unless $html_ref;
    
    my %result;
    
    $result{topic} = $self->{parser}->parse_board_topic($html_ref);

    $result{subboards}          = $self->{parser}->parse_board_subboards($html_ref);
    $result{tiezis} = $self->{parser}->parse_board_tiezis($html_ref);
    
    $result{board_num} = 1;
    $result{tiezi_num} = scalar(@{$result{tiezis}});
    
    my $result_urls_ref = $self->{parser}->parse_board_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    for my $u (@$result_urls_ref) {
        print "board : $u\n";
        my $h = $self->{browser}->get_url_ref($u);
        my $r = $self->{parser}->parse_board_tiezis($h);
        push @{$result{tiezis}} , @$r;
        
        $result{board_num}++;
        $result{tiezi_num} = scalar(@{$result{tiezis}});

        return \%result if($return_sub and $return_sub->(\%result));
    }
    
    return \%result;
} ## end sub get_board_ref

sub get_query_ref {
    my ( $self, $query, $return_sub) = @_;
    
    my ( $url, $post_vars ) = $self->{parser}->make_query_url( $query );
    
    my $html_ref = $self->{browser}->get_url_ref( $url, $post_vars );
    return unless $html_ref;

    my %result;
    $result{tiezis}          = $self->{parser}->parse_query($html_ref);

    my $result_urls_ref = $self->{parser}->get_query_result_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    for my $url (@$result_urls_ref) {
        my $h = $self->{browser}->get_url_ref($url);
        my $r = $self->{parser}->parse_query($h);
        push @{$result{tiezis}}, @$r;
        
        $result{query_num}++;
        $result{tiezi_num} = scalar(@{$result{tiezis}});

        return \%result if($return_sub and $return_sub->(\%result));
    }

    return \%result;
} ## end sub get_query_ref

sub select_tiezi {
    my ($self, $info_ref) = @_;

    my %menu = ( 'Select' => 'Many', 'Banner' => 'Book List', );

    #菜单项，不搞层次了，恩
    my %select;
    my $i = 1;
    for my $r (@$info_ref) {
        my $url = $r->{url};
        my $item = $r->{title};
        $item.=" --- $r->{name}" if($r->{name});
        $select{$item} = $r;
        $item = encode( locale => $item );
        $menu{"Item_$i"} = { Text => $item };
        $i++;
    } ## end for my $r (@$info_ref)

    #最后选出来的小说
    my @select_result;
    for my $item ( &Menu( \%menu ) ) {
        $item = decode( locale => $item );
        push @select_result, $select{$item} ;
    }

    return \@select_result;

} ## end sub select_book

no Moo;

1; # End of Tiezi::Robot
