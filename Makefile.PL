
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "\x{8d34}\x{5b50}\x{4e0b}\x{8f7d}\x{5668}",
  "AUTHOR" => "abbypan <abbypan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tiezi-Robot",
  "EXE_FILES" => [
    "bin/get_tiezi.pl",
    "bin/tiezi_to_any.pl"
  ],
  "LICENSE" => "perl",
  "NAME" => "Tiezi::Robot",
  "PREREQ_PM" => {
    "Encode::Locale" => 0,
    "JSON" => 0,
    "Novel::Robot::Browser" => 0,
    "Term::Menus" => 0,
    "Tiezi::Robot::Packer" => 0,
    "Tiezi::Robot::Parser" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.16",
  "test" => {
    "TESTS" => ""
  }
);


my %FallbackPrereqs = (
  "Encode::Locale" => 0,
  "JSON" => 0,
  "Novel::Robot::Browser" => 0,
  "Term::Menus" => 0,
  "Tiezi::Robot::Packer" => 0,
  "Tiezi::Robot::Parser" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



