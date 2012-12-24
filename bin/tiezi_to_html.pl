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

my $xs = Tiezi::Robot->new();
$xs->set_site($OPT{s}) if($OPT{s});

print "\rget tiezi to html : $tiezi_url";
my $tz = $xs->get_tiezi_ref($tiezi_url);
exit unless($tz);

my $filename = $OPT{f} || encode( locale  => "$tz->{topic}{name}-$tz->{topic}{title}.html");
open my $fh, '>:utf8', $filename;

my $css = get_css();
my $toc = $OPT{T}? '' : '<div id="toc"><ol> '.generate_toc($tz).' </ol></div>';
my $title = "$tz->{topic}{name} 《$tz->{topic}{title}》";
print $fh <<__HTML__;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title> $title </title>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<style type="text/css">
$css
</style>
</head>
<body>
<div id="title"><a href="$tiezi_url">$title</a></div>
$toc
<div id="content">

<div class="floor">
<div class="fltitle">000#<a name="toc0">$tz->{topic}{title} $tz->{topic}{time} $tz->{topic}{name}</a></div>
<div class="flcontent">$tz->{topic}{content}</div>
</div>
__HTML__

for my $i (0 .. $#{$tz->{floors}}){
    my $f = $tz->{floors}[$i];
    next unless(select_floor($f, $tz->{topic}, \%OPT));
    
    my $id = $f->{id} || ($i+1);

    my $j = sprintf ( "%03d# ", $id );
    my $floor = <<__FLOOR__;
<div class="floor">
<div class="fltitle">$j<a name="toc$id">$f->{title} $f->{time} $f->{name}</a></div>
<div class="flcontent">$f->{content}</div>
</div>
__FLOOR__
    print $fh $floor,"\n";
}
print $fh "</div></body></html>";
close $fh;
print "\n";

sub get_css
{
    my $css = <<__CSS__;
body {
	font-size: large;
	font-family: Verdana, Arial, Helvetica, sans-serif;
	margin: 1em 8em 1em 8em;
	text-indent: 2em;
	line-height: 145%;
}
#title, .fltitle {
	border-bottom: 0.2em solid #ee9b73;
	margin: 0.8em 0.2em 0.8em 0.2em;
	text-indent: 0em;
	font-size: x-large;
    font-weight: bold;
    padding-bottom: 0.25em;
}
#title, ol { line-height: 150%; }
#title { text-align: center; }
__CSS__
    return $css;
} ## end sub read_css

sub generate_toc {
    my ($r) = @_;
    my $toc=qq`<li><a href="#toc0">$r->{topic}{title} $r->{topic}{time} $r->{topic}{name}</a></li>\n`;
for my $i (0 .. $#{$tz->{floors}}){
    my $f = $tz->{floors}[$i];
    next unless(select_floor($f, $r->{topic}, \%OPT));
    my $id = $f->{id} || ($i+1);
    $toc.=qq`<li><a href="#toc$id">$f->{title} $f->{time} $f->{name}</a></li>\n`;
    }
    return $toc;
}

sub select_floor {
    my ($f, $t, $o) = @_;
    
    return 0 if(exists $o->{U} and $f->{name} ne $t->{name});
    
    if($o->{C}){
        my $c = $f->{content};
        $c=~s/<.+?>//sg;
        return 0 if(length($c) < $o->{C});    
    }
    
    return 1;
}
