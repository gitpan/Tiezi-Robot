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


-P : 取 top n 页

-F : 取 top n 楼

-W : 跟贴至少要 n 个字

-U : 只看楼主(默认是取出所有楼层，不只楼主)

-T : 生成的贴子不加楼层目录(默认是加楼层目录)

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

getopt( 'sufPFWUT', \%OPT );


my $tiezi_url = $OPT{u};

print "\rget tiezi to html : $tiezi_url";

my $xs = Tiezi::Robot->new();
$xs->set_parser($OPT{s} || $tiezi_url) ;
$xs->set_packer('HTML');
my $o = { 
        'with_toc' => $OPT{T} // 1, 
        'only_poster' => $OPT{U} // undef, 
        'min_word_num' => $OPT{W} // undef, 
        'max_page_num' => $OPT{P} // undef, 
        'max_floor_num' => $OPT{F} // undef,
};
$xs->get_tiezi($tiezi_url, $o);
