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

our $VERSION=0.11;

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


    my $tz = $self->get_tiezi_ref($tz_url, $o);
    return unless ($tz and $tz->{topic} and $tz->{topic}{name} and $tz->{topic}{title});
    $tz->{topic}{url} = $tz_url;

    check_skip_floor($_, $o, $tz) for @{$tz->{floors}};

    $self->{packer}->open_packer($tz);

    $self->{packer}->format_before_toc($tz);

    $self->{packer}->format_toc($tz) if($o->{with_toc});

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

sub check_skip_floor {
    my ($d, $o, $tz) = @_;
    return if(is_poster_floor($d, $o, $tz) and is_wordnum_overflow($d, $o));
    $d->{skip} = 1;
}

sub is_wordnum_overflow {
    my ( $floor, $o ) = @_;
    return 1 unless($o->{min_word_num});
    my $n = length( $floor->{content} );
    return 1 if ( $n >= $o->{min_word_num} );
    return;
}

sub is_poster_floor {
    my ( $floor, $o, $r ) = @_;
    return 1 unless($o->{only_poster});

    return 1 if ( $floor->{name} eq $r->{topic}{name} );
    return;
}

sub is_tiezi_overflow {
    my ($f, $o) = @_;

    return unless($o->{max_tiezi_num});

    my $tiezi_num = scalar(@$f);
    return if($tiezi_num < $o->{max_tiezi_num});

    $#$f = $o->{max_tiezi_num} - 1;
    return 1;
}

sub is_floor_overflow {
    my ($f, $o) = @_;

    return unless($o->{max_floor_num});

    my $floor_num = scalar(@$f);
    return if($floor_num < $o->{max_floor_num});

    $#$f = $o->{max_floor_num} - 1;
    return 1;
}

sub is_page_overflow {
    my ($i, $o) = @_;
    return unless($o->{max_page_num});
    return if($i<$o->{max_page_num});
    return 1;
}

sub get_tiezi_ref {
    my ( $self, $url, $o ) = @_;
    $o ||= {};
    
    my $html_ref = $self->{browser}->request_url( $url );
    return unless $html_ref;
    
    my %result;
    
    $result{topic} = $self->{parser}->parse_tiezi_topic($html_ref);
    $result{floors}          = $self->{parser}->parse_tiezi_floors($html_ref);
    return \%result if(is_floor_overflow($result{floors}, $o));

    my $result_urls_ref = $self->{parser}->parse_tiezi_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    my $page_num = 2;
    for my $u (@$result_urls_ref) {

        my $h = $self->{browser}->request_url($u);
        my $r = $self->{parser}->parse_tiezi_floors($h);
        push @{$result{floors}} , @$r;

        return \%result if(is_floor_overflow($result{floors}, $o));
        return \%result if(is_page_overflow($page_num, $o));

        $page_num++; 
    }
    
    return \%result;
} ## end sub get_tiezi_ref

sub get_board_ref {
    my ( $self, $url , $o ) = @_;
    
    my $html_ref = $self->{browser}->request_url( $url );
    print "board : $url\n";
    return unless $html_ref;
    
    my %result;
    
    $result{topic} = $self->{parser}->parse_board_topic($html_ref);

    $result{subboards}          = $self->{parser}->parse_board_subboards($html_ref);
    $result{tiezis} = $self->{parser}->parse_board_tiezis($html_ref);
    return \%result if(is_tiezi_overflow($result{tiezis}, $o));
    
    my $result_urls_ref = $self->{parser}->parse_board_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    my $page_num = 2;
    for my $u (@$result_urls_ref) {
        print "board : $u\n";
        my $h = $self->{browser}->request_url($u);
        my $r = $self->{parser}->parse_board_tiezis($h);
        push @{$result{tiezis}} , @$r;
        
        return \%result if(is_tiezi_overflow($result{tiezis}, $o));
        return \%result if(is_page_overflow($page_num, $o));
        $page_num++;
    }
    
    return \%result;
} ## end sub get_board_ref

sub get_query_ref {
    my ( $self, $query, $o) = @_;
    $o ||= {};

    my ( $url, $post_vars ) = $self->{parser}->make_query_request( $query );
    
    my $html_ref = $self->{browser}->request_url( $url, $post_vars );
    return unless $html_ref;

    my %result;
    $result{tiezis}          = $self->{parser}->parse_query($html_ref);
    return \%result if(is_tiezi_overflow($result{tiezis}, $o));

    my $result_urls_ref = $self->{parser}->parse_query_result_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    my $page_num = 2;
    for my $url (@$result_urls_ref) {
        my $h = $self->{browser}->request_url($url);
        my $r = $self->{parser}->parse_query($h);
        push @{$result{tiezis}}, @$r;
        
        return \%result if(is_tiezi_overflow($result{tiezis}, $o));
        return \%result if(is_page_overflow($page_num, $o));
        $page_num++;
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
