use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Tiezi::Robot',
    AUTHOR           => q{Abby Pan <abbypan@gmail.com>},
    VERSION_FROM     => 'lib/Tiezi/Robot.pm',
    ABSTRACT_FROM    => 'lib/Tiezi/Robot.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    EXE_FILES => [
        'bin/get_tiezi_to_html.pl',
    ], 
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Novel::Robot::Browser' => 0.02, 
        'Moo' => 1.000007,
        'Encode::Locale'=> 1.03, 
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Tiezi-Robot-*' },
);
