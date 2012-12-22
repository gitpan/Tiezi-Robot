#===============================================================================
#  DESCRIPTION: 帖子下载器
#       AUTHOR: Abby Pan (USTC), abbypan@gmail.com
#      CREATED: 2012年12月22日 23时36分55秒
#===============================================================================

=head1 NAME

Tiezi::Robot - 帖子下载器

=head2 支持站点

=item *

HJJ : 红晋江 http://bbs.jjwxc.net

=back

=head1 EXAMPLE

get_tiezi_to_html.pl -u http://bbs.jjwxc.net/showmsg.php?board=153&id=57 -U -C 100

=cut

use strict;
use warnings;
 
package Tiezi::Robot;

use 5.006;
use strict;
use warnings;
use utf8;


our $VERSION = '0.01';

use Encode;
use Moo;

use Novel::Robot::Browser;
use Tiezi::Robot::Parser::HJJ; 

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
    is => 'rw', 
    lazy => 1, 
    default => \&set_site, 
);

sub set_site {
        my ($self, $site) = @_;
        $self->{site} = $site if($site);
        $self->{parser_list}{$self->{site}} //= eval qq[new Tiezi::Robot::Parser::$self->{site}()];
        $self->{parser}  = $self->{parser_list}{$self->{site}};
}

sub set_site_by_url {
        my ($self, $url) = @_;

        my $site = ($url=~m#^http://bbs\.jjwxc\.net/#) ? 'HJJ'  : 
        '';

        $self->set_site($site) if(! $self->{site} or $self->{site} ne $site);
}

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

no Moo;

1; # End of Tiezi::Robot
