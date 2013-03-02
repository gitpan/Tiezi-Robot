#!/usr/bin/perl 
# ABSTRACT: 下载帖子，存成html

=pod

=encoding utf8

=head1 USAGE

    #取出指定帖子，只看楼主，且跟帖内容不能少于100字 

    tiezi_to_html.pl -u "http://bbs.jjwxc.net/showmsg.php?board=153&id=57" -U 1 -C 100

=head1 OPTIONS

-s : 站点类型

-u : 帖子url

-f : 输出html文件名(默认是 作者-帖子标题.html)

-T : 生成的贴子不加楼层目录(默认是加楼层目录)

-U : 只看楼主(默认是取出所有楼层，不只楼主)

-C : 跟帖内容不能少于多少字

=cut

use strict;
use warnings;
use utf8;

use Tiezi::Robot;

use Encode::Locale;
use Encode;
use Getopt::Std;

use vars qw/%OPT/;


$|=1;

getopt( 'sufTUC', \%OPT );


my $tiezi_url = $OPT{u};

print "\rget tiezi to html : $tiezi_url";

my $xs = Tiezi::Robot->new();
$xs->set_parser($OPT{s} || $tiezi_url) ;
$xs->set_packer('HTML');
$xs->get_tiezi($tiezi_url, { 'skip_floor' => sub { skip_floor(@_, \%OPT); }, });

sub skip_floor {
    my ($t, $f, $o) = @_;

    return 1 if(exists $o->{U} and $f->{name} ne $t->{topic}{name});

    if($o->{C}){
        my $c = $f->{content};
        $c=~s/<.+?>//sg;
        return 1 if(length($c) < $o->{C});    
    }

    return 0;
}
