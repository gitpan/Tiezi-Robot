#!/usr/bin/perl 
#  ABSTRACT:  指定条件，TERM下面选择下载帖子

=pod

=encoding utf8

=head1 USAGE

    #取出指定帖子，手动选择，只看楼主，且跟帖内容不能少于100字 

    tiezi_to_any.pl -b "http://bbs.jjwxc.net/board.php?board=153&page=1" -o "-p 2" -t "tiezi_to_html.pl -u \"{url}\" -U 1 -C 100" -m 1

    #取出指定帖子，手动选择，只看楼主，且跟帖内容不能少于100字 

    tiezi_to_any.pl -s HJJ -o "153 贴子主题 迷侠记[初版]" -t "tiezi_to_html.pl -u \"{url}\" -U 1 -C 100" -m 1

=head1 OPTIONS

-b : board

-s(query) : site

-o : board option / query keyword

-m : select menu

-t : to html / ...

=cut

use strict;
use warnings;
use utf8;
use JSON;
use Encode::Locale;
use Encode;
use Term::Menus;

use Getopt::Std;

$| = 1;

my %opt;
getopt( 'bsomt', \%opt );


my $cmd = $opt{b} ? qq[tiezi_board_to_json.pl -u '$opt{b}' $opt{o}] : qq[tiezi_query_to_json.pl $opt{s} $opt{o}];

print $cmd;
my $json = `$cmd`;
my $info = decode_json( $json );

my $select = $opt{m} ? select_book($info) : $info; 
print $_->{url},"\n" for @$select;
for my $r (@$select){
    my $u = $r->{url};
    my $c = $opt{t};
    $c=~s/{url}/$u/;
    system($c);
}

sub select_book {
    my ($info_ref ) = @_;

    my %menu = ( 'Select' => 'Many', 'Banner' => 'Tiezi List', );

    #菜单项，不搞层次了，恩
    my %select;
    my $i = 1;
    for my $r (@$info_ref) {
        my $item = "$i --- $r->{title}";
        $select{$item} = $r->{url};
        $item = encode( locale => $item );
        $menu{"Item_$i"} = { Text => $item };
        $i++;
    } ## end for my $r (@$info_ref)

    #最后选出来的小说
    my @select_result;
    for my $item ( &Menu( \%menu ) ) {
        $item = decode( locale => $item );
        my ( $i, $t ) = ( $item =~ /^(.*) --- (.*)$/ );
        push @select_result, { url =>  $select{$item} };
    }

    return \@select_result;

} ## end sub select_book
