#===============================================================================
#  DESCRIPTION:  各站点的解析引擎
#       AUTHOR:  AbbyPan (USTC), <abbypan@gmail.com>
#===============================================================================
package  Tiezi::Robot::Parser::Base;
use strict;
use warnings;
use Moo;

has base => (
    #网站基地址
    is => 'rw',
);

has site => (

    #网站名称
    is => 'rw',
);

has charset => (

    is => 'rw',
);

sub parse_tiezi_topic {
    #主题贴内容
}

sub parse_tiezi_floors {
    #跟帖内容
    
}

sub parse_tiezi_urls {
    #帖子分页url 
}


no Moo;
1;
