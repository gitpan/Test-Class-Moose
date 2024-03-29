
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.014.
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Serious testing for serious Perl",
  "AUTHOR" => "Curtis \"Ovid\" Poe <ovid\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Class-Moose",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::Class::Moose",
  "PREREQ_PM" => {
    "Benchmark" => 0,
    "Carp" => 0,
    "Class::MOP" => 0,
    "File::Find" => 0,
    "File::Spec" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Moose" => "2.0000",
    "Moose::Role" => "2.0000",
    "Moose::Util::TypeConstraints" => 0,
    "Parallel::ForkManager" => 0,
    "Sub::Attribute" => 0,
    "TAP::Formatter::Color" => 0,
    "TAP::Stream" => "0.44",
    "Test::Builder" => 0,
    "Test::Most" => "0.32",
    "Try::Tiny" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Carp::Always" => 0,
    "Scalar::Util" => 0,
    "Test::Requires" => 0,
    "Test::Warnings" => 0,
    "lib" => 0
  },
  "VERSION" => "0.58",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Benchmark" => 0,
  "Carp" => 0,
  "Carp::Always" => 0,
  "Class::MOP" => 0,
  "File::Find" => 0,
  "File::Spec" => 0,
  "List::MoreUtils" => 0,
  "List::Util" => 0,
  "Moose" => "2.0000",
  "Moose::Role" => "2.0000",
  "Moose::Util::TypeConstraints" => 0,
  "Parallel::ForkManager" => 0,
  "Scalar::Util" => 0,
  "Sub::Attribute" => 0,
  "TAP::Formatter::Color" => 0,
  "TAP::Stream" => "0.44",
  "Test::Builder" => 0,
  "Test::Most" => "0.32",
  "Test::Requires" => 0,
  "Test::Warnings" => 0,
  "Try::Tiny" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



