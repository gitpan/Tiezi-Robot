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

    tiezi_board_to_json.pl -u "http://bbs.jjwxc.net/board.php?board=153&page=1" -t 50 -p 3 
    
    #在红晋江 第 153 版块 查询主题 为 迷侠 的贴子

    tiezi_query_to_json.pl HJJ 153 贴子主题 迷侠
    
    #取出红晋江版块153的贴子（超出15个则停止），手动选择贴子后，自动保存为html，只看楼主，且跟贴内容不能少于100字

    tiezi_to_any.pl -b "http://bbs.jjwxc.net/board.php?board=153&page=1" -o "-t 15" -t "tiezi_to_html.pl -u \"{url}\" -U 1 -C 100" -m 1
    
    #取出红晋江版块153中主题出现“迷侠记[初版]”的贴子，进行手动选择，然后存成html（只看楼主，且跟帖内容不能少于100字）

    tiezi_to_any.pl -s HJJ -o "153 贴子主题 迷侠记[初版]" -t "tiezi_to_html.pl -u \"{url}\" -U 1 -C 100" -m 1

=cut

use strict;
use warnings;
 
package Tiezi::Robot;

use 5.006;
use utf8;

use Encode;
use Moo;
use Novel::Robot::Browser;
use Tiezi::Robot::Parser; 

has browser => ( is => 'rw', 
    default => sub {
        my ($self) = @_;
        my $browser = new Novel::Robot::Browser();
        return $browser;
    },
);

has site => (
    is => 'rw', 
    default => sub { '' }, 
);

has parser => (
    is      => 'rw',
    default => sub {
        my ($self) = @_;
        my $parser_base = new Tiezi::Robot::Parser();
        my $parser = $parser_base->init_parser('Base');
        return $parser;
    },
);

sub set_site {
    my ( $self, $site ) = @_;
    $self->{site} = $site if ($site);
    unless($self->{parser_list}{ $self->{site} }){
        my $parser_base = new Tiezi::Robot::Parser();
        $self->{parser_list}{ $self->{site} }
        = $parser_base->init_parser($self->{site});
    }
    $self->{parser} = $self->{parser_list}{ $self->{site} };
} ## end sub set_site

sub set_site_by_url {
    my ( $self, $url ) = @_;

    my $site = $self->{parser}->detect_site_by_url($url);
    
    $self->set_site($site) if ( !$self->{site} or $self->{site} ne $site );
} ## end sub set_site_by_url

sub get_tiezi_ref {
    my ( $self, $url ) = @_;
    
    $self->set_site_by_url($url);

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
    
    $self->set_site_by_url($url);

    my $html_ref = $self->{browser}->get_url_ref( $url );
    return unless $html_ref;
    
    my %result;
    
    $result{topic} = $self->{parser}->parse_board_topic($html_ref);
    $result{subboards}          = $self->{parser}->parse_board_subboards($html_ref);
    $result{tiezis} = $self->{parser}->parse_board_tiezis($html_ref);
    
    $result{parsed_board_page_num} = 1;
    $result{parsed_tiezi_url_num} = scalar(@{$result{tiezis}});
    
    my $result_urls_ref = $self->{parser}->parse_board_urls($html_ref);
    return $result{tiezis} unless ( defined $result_urls_ref );

    for my $u (@$result_urls_ref) {
        my $h = $self->{browser}->get_url_ref($u);
        my $r = $self->{parser}->parse_board_tiezis($h);
        push @{$result{tiezis}} , @$r;
        
        $result{parsed_board_page_num}++;
        $result{parsed_tiezi_url_num} = scalar(@{$result{tiezis}});
        return $result{tiezis} if($return_sub and $return_sub->(\%result));
    }
    
    return $result{tiezis};
} ## end sub get_board_ref

sub get_query_ref {
    my ( $self, @args) = @_;
    
    $args[-1] = encode( $self->{parser}->charset, $args[-1] );
    my ( $url, $post_vars ) = $self->{parser}->make_query_url( @args );
    
    my $html_ref = $self->{browser}->get_url_ref( $url, $post_vars );
    return unless $html_ref;

    my $result          = $self->{parser}->parse_query($html_ref);
    my $result_urls_ref = $self->{parser}->get_query_result_urls($html_ref);
    return $result unless ( defined $result_urls_ref );

    my $i=0;
    for my $url (@$result_urls_ref) {
        my $h = $self->{browser}->get_url_ref($url);
        my $r = $self->{parser}->parse_query($h);
        push @$result, @$r;
        $i++;
        last if($i>2);
    }

    return $result;
} ## end sub get_query_ref

no Moo;

1; # End of Tiezi::Robot
