#!/usr/bin/perl 
# ABSTRACT: 解析版块内贴子信息，以JSON输出
=pod

=encoding utf8

=head1 DESC

解析版块内贴子信息，以JSON输出

=head1 USAGE

    #取出贴子URL信息，超出50贴就停止

    tiezi_board_to_json.pl -u "http://bbs.jjwxc.net/board.php?board=3&page=1" -t 50 

    #取出贴子URL信息，超出3页就停止

    tiezi_board_to_json.pl -u "http://bbs.jjwxc.net/board.php?board=3&page=1" -p 3 
    
    #取出贴子URL信息，超出50贴或超出3页就停止
    
    tiezi_board_to_json.pl -u "http://bbs.jjwxc.net/board.php?board=3&page=1" -t 50 p 3 

=cut

use strict;
use warnings;
use utf8;
use JSON;
use Getopt::Std;

use Tiezi::Robot;

my %opt;
my $return_sub;

getopt('upt', \%opt);

if($opt{p} or $opt{t}){
    $return_sub = sub {
        my ($r) = @_;
        if($opt{p}){
            return 1 if($r->{parsed_board_page_num} > $opt{p});
        }
        if($opt{t}){
            return 1 if($r->{parsed_tiezi_url_num} > $opt{t});
        }
        return 0;
    };
}


my $xs = Tiezi::Robot->new();
my $board_ref = $xs->get_board_ref($opt{u}, $return_sub);
exit unless($board_ref);

my $board_json = encode_json $board_ref;
print $board_json;
