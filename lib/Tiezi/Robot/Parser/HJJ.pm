#===============================================================================
#  DESCRIPTION:  红晋江的解析模块
#       AUTHOR:  AbbyPan (USTC), <abbypan@gmail.com>
#===============================================================================
package Tiezi::Robot::Parser::HJJ;
use strict;
use warnings;
use utf8;
use Moo;
extends 'Tiezi::Robot::Parser::Base';
use Encode;

has '+base'  => ( default => sub {'http://bbs.jjwxc.net'} );
has '+site'    => ( default => sub {'HJJ'} );
has '+charset' => ( default => sub {'cp936'} );

sub parse_tiezi_topic {
        my ($self, $html_ref) = @_;
		my %t;
        for ($$html_ref){
            
		($t{title})= 
        m{<td bgcolor="#E8F3FF"><div style="float: left;">\s*主题：(.+?)<font color="#999999" size="-1">}s;
        ($t{content}) = m{<td class="read"><div id="topic">(.*?)</div>\s*</td>\s*</tr>\s*</table>}s;
        $t{content}=~s#</?font[^>]+>##sg;
        ( $t{name}, $t{time} ) =
              m#№0&nbsp;</font>.*?☆☆☆</font>(.*?)</b><font color="99CC00">于</font>(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})留言#s;
          $t{name}=~s/<\/?(font|b).*?>//gsi;
          $t{id} = 0;
        }
        
        return \%t;
}

sub parse_tiezi_floors {
    my ($self, $html_ref) = @_;
    
    my @floor;
    while ($$html_ref=~m#(<tr>\s+<td colspan="2">.*?<td><font color=99CC00 size="-1">.*?</tr>)#gis) {
        my $cell = $1;
        next unless($cell);

        my %fl;

        ( $fl{name}, $fl{time} ) =
        $cell =~ m#☆☆☆</font>(.*?)</b><font color="99CC00">于</font>(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})留言#s;
        $fl{name}=~s/<\/?(font|b).*?>//gsi;

        ( $fl{content} ) = $cell =~
        m{<tr>\s*<td[^>]*class="read">\s*(.*?)\s*</td>\s*</tr>\s*</table>}s;
        $fl{content}=~s#本帖尚未审核,若发布24小时后仍未审核通过会被屏蔽##s;
        $fl{content}=~s#</?font[^>]+>##sg;
        $fl{title} = '';
        ($fl{id}) = $cell=~m{№(\d+)</font>}s;
        
        push @floor, \%fl;
}

    return \@floor;
}

sub parse_tiezi_urls {
    my ($self, $html_ref) = @_;
    my ($page_info) = $$html_ref=~m[<div id="pager_top" align="center" style="padding:10px;">(.+?)</div>]s;
    return unless($page_info);
    my ($page_num, $page_url)  = $page_info=~m[共(\d+)页.+?<a href=(.+?page=)\d]s;
    my @urls = map { "$self->{base}/showmsg.php$page_url$_" } ( 1 .. $page_num-1 );
    return \@urls;
}

no Moo;
1;
