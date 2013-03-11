
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "\350\264\264\345\255\220\344\270\213\350\275\275\345\231\250",
  "AUTHOR" => "abbypan <abbypan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tiezi-Robot",
  "EXE_FILES" => [
    "bin/tiezi_to_any.pl",
    "bin/tiezi_to_html.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Tiezi::Robot",
  "PREREQ_PM" => {
    "Encode::Locale" => "1.03",
    "JSON" => "2.53",
    "Moo" => "1.000007",
    "Novel::Robot::Browser" => "0.06",
    "Term::Menus" => "2.21",
    "Tiezi::Robot::Packer" => "0.01",
    "Tiezi::Robot::Parser" => "0.05"
  },
  "VERSION" => "0.09",
  "test" => {
    "TESTS" => ""
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



