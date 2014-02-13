# ABSTRACT: 贴子下载器
package Tiezi::Robot;

our $VERSION = 0.15;

use strict;
use warnings;
use utf8;

use Novel::Robot::Browser;
use Tiezi::Robot::Parser;
use Tiezi::Robot::Packer;

use Encode;
use Term::Menus;

sub new {
    my ( $self, %opt ) = @_;
    my $browser =  Novel::Robot::Browser->new(%opt);
    my $parser  = Tiezi::Robot::Parser->new(%opt);
    my $packer  = Tiezi::Robot::Packer->new(%opt);
    bless {
        browser => $browser, 
        parser => $parser, 
        packer => $packer, 
        %opt, 
    }, __PACKAGE__;
}

sub set_parser {
    my ( $self, $s ) = @_;
    $self->{parser} = Tiezi::Robot::Parser->new( site => $s );
} ## end sub set_parser

sub set_packer {
    my ( $self, $t ) = @_;
    $self->{packer} = Tiezi::Robot::Packer->new( type => $t );
} ## end sub set_packer

sub get_tiezi {
    my ( $self, $tz_url, %o ) = @_;

    my $tz = $self->get_tiezi_ref( $tz_url, %o );
    return
      unless ( $tz
        and $tz->{topic}
        and $tz->{topic}{name}
        and $tz->{topic}{title} );

    $self->format_tiezi_output( $tz, \%o );
    $self->{packer}->main( $tz, %o );
}

sub format_tiezi_output {
    my ( $self, $tz, $o ) = @_;
    if ( !exists $o->{output} ) {
        my $html = '';
        $o->{output} =
          exists $o->{output_scalar}
          ? \$html
          : $self->format_default_filename($tz);
    }
    return $o->{output};
}

sub format_default_filename {
    my ( $self, $tz ) = @_;
    return "$tz->{topic}{name}-$tz->{topic}{title}.".$self->{packer}->suffix();
}

sub check_skip_floors {
    my ( $tz, $o ) = @_;
    for my $d ( @{ $tz->{floors} } ) {
        next
          if (  is_poster_floor( $d, $o, $tz )
            and is_wordnum_overflow( $d, $o ) );
        $d->{skip} = 1;
    }
}

sub is_wordnum_overflow {
    my ( $floor, $o ) = @_;
    return 1 unless ( $o->{min_word_num} );

    my $c = $floor->{content};
    $c =~ s/<[^>]+>//sg;
    $c =~ s/\s+//gs;
    my $n = length($c);

    return 1 if ( $n >= $o->{min_word_num} );
    return;
}

sub is_poster_floor {
    my ( $floor, $o, $r ) = @_;
    return 1 unless ( $o->{only_poster} );

    return 1 if ( $floor->{name} eq $r->{topic}{name} );
    return;
}

sub is_tiezi_overflow {
    my ( $f, $o ) = @_;

    return unless ( $o->{max_tiezi_num} );

    my $tiezi_num = scalar(@$f);
    return if ( $tiezi_num < $o->{max_tiezi_num} );

    $#$f = $o->{max_tiezi_num} - 1;
    return 1;
}

sub is_floor_overflow {
    my ( $f, $o ) = @_;

    return unless ( $o->{max_floor_num} );

    my $floor_num = scalar(@$f);
    return if ( $floor_num < $o->{max_floor_num} );

    $#$f = $o->{max_floor_num} - 1;
    return 1;
}

sub is_page_overflow {
    my ( $i, $o ) = @_;
    return unless ( $o->{max_page_num} );
    return if ( $i < $o->{max_page_num} );
    return 1;
}

sub get_tiezi_ref {
    my ( $self, $url, %o ) = @_;
    my $tz = $self->get_tiezi_raw( $url, \%o );
    check_skip_floors( $tz, \%o );
    return $tz;
}

sub get_tiezi_raw {
    my ( $self, $url, $o ) = @_;

    my $html_ref = $self->{browser}->request_url($url);
    return unless $html_ref;

    my %result;
    $result{floors} = $self->{parser}->parse_tiezi_floors($html_ref);

    $result{topic} = $self->{parser}->parse_tiezi_topic($html_ref);
    $result{topic}{url} = $url;

    unshift @{ $result{floors} }, $result{topic}
      if ( exists $result{topic}{content} );

    return \%result if ( is_floor_overflow( $result{floors}, $o ) );

    my $result_urls_ref = $self->{parser}->parse_tiezi_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    my $page_num = 2;
    for my $u (@$result_urls_ref) {
        return \%result if ( is_page_overflow( $page_num, $o ) );
        return \%result if ( is_floor_overflow( $result{floors}, $o ) );

        my $h = $self->{browser}->request_url($u);
        my $r = $self->{parser}->parse_tiezi_floors($h);
        push @{ $result{floors} }, @$r;

        $page_num++;
    }

    return \%result;
} ## end sub get_tiezi_ref

sub get_board_ref {
    my ( $self, $url, $o ) = @_;

    my $html_ref = $self->{browser}->request_url($url);
    print "board : $url\n";
    return unless $html_ref;

    my %result;

    $result{topic} = $self->{parser}->parse_board_topic($html_ref);

    $result{subboards} = $self->{parser}->parse_board_subboards($html_ref);
    $result{tiezis}    = $self->{parser}->parse_board_tiezis($html_ref);
    return \%result if ( is_tiezi_overflow( $result{tiezis}, $o ) );

    my $result_urls_ref = $self->{parser}->parse_board_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    my $page_num = 2;
    for my $u (@$result_urls_ref) {
        return \%result if ( is_page_overflow( $page_num, $o ) );
        return \%result if ( is_tiezi_overflow( $result{tiezis}, $o ) );
        print "board : $u\n";
        my $h = $self->{browser}->request_url($u);
        my $r = $self->{parser}->parse_board_tiezis($h);
        push @{ $result{tiezis} }, @$r;

        $page_num++;
    }

    return \%result;
} ## end sub get_board_ref

sub get_query_ref {
    my ( $self, $keyword, %opt ) = @_;

    my ( $url, $post_vars ) =
      $self->{parser}->make_query_request( $keyword, %opt );
    my $html_ref = $self->{browser}->request_url( $url, $post_vars );
    return unless $html_ref;

    my %result;
    $result{tiezis} = $self->{parser}->parse_query($html_ref);
    return \%result if ( is_tiezi_overflow( $result{tiezis}, \%opt ) );

    my $result_urls_ref = $self->{parser}->parse_query_result_urls($html_ref);
    return \%result unless ( defined $result_urls_ref );

    my $page_num = 2;
    for my $url (@$result_urls_ref) {
        return \%result if ( is_tiezi_overflow( $result{tiezis}, \%opt ) );
        return \%result if ( is_page_overflow( $page_num, \%opt ) );

        my $h = $self->{browser}->request_url($url);
        my $r = $self->{parser}->parse_query($h);
        push @{ $result{tiezis} }, @$r;

        $page_num++;
    }

    return \%result;
} ## end sub get_query_ref

sub select_tiezi {
    my ( $self, $info_ref ) = @_;

    my %menu = ( 'Select' => 'Many', 'Banner' => 'Book List', );

    #菜单项，不搞层次了，恩
    my %select;
    my $i = 1;
    for my $r (@$info_ref) {
        my $url  = $r->{url};
        my $item = $r->{title};
        $item .= " --- $r->{name}" if ( $r->{name} );
        $select{$item} = $r;
        $item = encode( locale => $item );
        $menu{"Item_$i"} = { Text => $item };
        $i++;
    } ## end for my $r (@$info_ref)

    #最后选出来的小说
    my @select_result;
    for my $item ( &Menu( \%menu ) ) {
        $item = decode( locale => $item );
        push @select_result, $select{$item};
    }

    return \@select_result;

} ## end sub select_book

1;    # End of Tiezi::Robot
