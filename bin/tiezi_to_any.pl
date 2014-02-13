#!/usr/bin/perl 

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

my $xs = Tiezi::Robot->new(
type => $opt{t} || 'html', 
site => $opt{s} || $opt{b}, 
);

my $tiezis_ref;

if ( $opt{q} ) {
    my $keyword = decode( locale => $opt{v} );
    my $query_ref = $xs->get_query_ref( $keyword, 
            board => decode( locale => $opt{b} ), 
            query    => decode( locale => $opt{q} ),
            'max_page_num' => $opt{M}, 
            'max_tiezi_num' => $opt{N}, 
        );
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

    print encode(locale =>$u), "\n";

    $xs->get_tiezi($u, 
        'with_toc' => $opt{T} // 1, 
        'only_poster' => $opt{U} // undef, 
        'min_word_num' => $opt{W} // undef, 
        'max_page_num' => $opt{P} // undef, 
        'max_floor_num' => $opt{F} // undef,
    );
}

sub return_sub {
    my ($r) = @_;
    #return 1 if ( $r->{tiezi_num} > 20 );
    return;
}
